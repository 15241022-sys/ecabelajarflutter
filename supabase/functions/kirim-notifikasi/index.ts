// Edge Function: kirim push notification via Firebase Cloud Messaging (HTTP v1).
// Dipanggil oleh trigger database (pg_net) saat:
//   - ada pesanan baru (INSERT)            -> dikirim ke perangkat admin cabang terkait
//   - status pesanan menjadi "siap_diambil" -> dikirim ke perangkat pemilik pesanan
//
// Secret yang dibutuhkan (Edge Functions > Secrets):
//   FIREBASE_SERVICE_ACCOUNT  isi file JSON service account (atau versi base64-nya)
//   WEBHOOK_SECRET            string acak, harus sama dengan di supabase_notifikasi.sql
//   APP_URL                   (opsional) alamat aplikasi web, dibuka saat notifikasi diklik

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const DB_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_ANON_KEY") ??
  "";
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET") ?? "";
const APP_URL =
  Deno.env.get("APP_URL") ?? "https://15241022-sys.github.io/ecabelajarflutter/";

// ---------- helper: Supabase REST ----------
// Hanya header "apikey" yang dikirim (kompatibel dengan key format baru).
async function rest(path: string, init: RequestInit = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: DB_KEY, ...(init.headers ?? {}) },
  });
  if (!res.ok && init.method !== "DELETE") {
    throw new Error(`Supabase ${res.status}: ${await res.text()}`);
  }
  return res;
}

// ---------- helper: OAuth2 access token untuk FCM ----------
function loadServiceAccount() {
  const raw = (Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "").trim();
  if (!raw) throw new Error("Secret FIREBASE_SERVICE_ACCOUNT belum diisi");
  return JSON.parse(raw.startsWith("{") ? raw : atob(raw));
}

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  let s = "";
  bytes.forEach((b) => (s += String.fromCharCode(b)));
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claim}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`Token OAuth gagal: ${await res.text()}`);
  return (await res.json()).access_token as string;
}

// ---------- kirim satu pesan ke satu token ----------
async function kirim(
  projectId: string,
  accessToken: string,
  token: string,
  judul: string,
  isi: string,
  data: Record<string, string>,
) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: judul, body: isi },
          data,
          android: { priority: "HIGH" },
          webpush: {
            headers: { Urgency: "high" },
            notification: { icon: `${APP_URL}icons/Icon-192.png` },
            fcm_options: { link: APP_URL },
          },
        },
      }),
    },
  );

  if (res.ok) return true;

  // Token sudah tidak valid (aplikasi di-uninstall / izin dicabut): bersihkan.
  const err = await res.json().catch(() => null);
  const kode = err?.error?.details?.find?.((d: { errorCode?: string }) => d.errorCode)
    ?.errorCode ?? err?.error?.status;
  if (kode === "UNREGISTERED" || kode === "NOT_FOUND" || res.status === 404) {
    await rest(`device_tokens?token=eq.${encodeURIComponent(token)}`, {
      method: "DELETE",
    });
  } else {
    console.error("FCM gagal:", res.status, JSON.stringify(err));
  }
  return false;
}

async function namaCabangDari(id: number | null): Promise<string> {
  if (id == null) return "";
  try {
    const rows = await rest(`cabang?select=nama&id=eq.${id}`).then((r) => r.json());
    return rows[0]?.nama ?? "";
  } catch {
    return "";
  }
}

const rupiah = (n: unknown) => "Rp" + Number(n ?? 0).toLocaleString("id-ID");
const json = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!WEBHOOK_SECRET || req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
    return json({ error: "Unauthorized" }, 401);
  }

  try {
    const payload = await req.json();
    const tipe: string = payload.type;
    const rec = payload.record ?? {};
    const old = payload.old_record ?? {};

    let target: string;
    let judul: string;
    let isi: string;
    let tokens: string[];

    if (tipe === "INSERT") {
      // Pesanan baru -> perangkat admin yang sedang mengelola cabang tersebut
      const cabangId = rec.cabang_id != null ? Number(rec.cabang_id) : null;
      const [nama, namaCabang] = await Promise.all([
        rest(`users?select=nama&id=eq.${Number(rec.user_id)}`)
          .then((r) => r.json())
          .then((r) => r[0]?.nama ?? "Pelanggan"),
        namaCabangDari(cabangId),
      ]);
      const jadwal = rec.jadwal_ambil
        ? " • Jadwal " + new Date(rec.jadwal_ambil).toLocaleString("id-ID", {
          timeZone: "Asia/Jakarta", // ubah jika outlet di zona waktu lain
          day: "numeric",
          month: "short",
          hour: "2-digit",
          minute: "2-digit",
        })
        : "";
      judul = `Pesanan baru #${rec.id}` + (namaCabang ? ` • ${namaCabang}` : "");
      isi = `${nama} • ${rupiah(rec.total_harga)} • ${
        rec.metode_pembayaran === "qris" ? "QRIS" : "Cash"
      }${jadwal}`;
      target = "admin";
      // Perangkat admin yang belum memilih cabang (cabang_id kosong) tetap
      // menerima semua pesanan sebagai cadangan.
      const filterCabang = cabangId != null
        ? `&or=(cabang_id.eq.${cabangId},cabang_id.is.null)`
        : "";
      tokens = await rest(
        `device_tokens?select=token&role=eq.admin${filterCabang}`,
      )
        .then((r) => r.json())
        .then((rows: { token: string }[]) => rows.map((x) => x.token));
    } else if (
      tipe === "UPDATE" && rec.status === "siap_diambil" &&
      old.status !== "siap_diambil"
    ) {
      // Pesanan siap diambil -> perangkat pemilik pesanan
      const namaCabang = await namaCabangDari(
        rec.cabang_id != null ? Number(rec.cabang_id) : null,
      );
      judul = "Pesanan siap diambil";
      isi = `Pesanan #${rec.id} sudah siap. Silakan ambil di outlet${
        namaCabang ? " " + namaCabang : ""
      }.`;
      target = "member";
      tokens = await rest(
        `device_tokens?select=token&user_id=eq.${Number(rec.user_id)}`,
      )
        .then((r) => r.json())
        .then((rows: { token: string }[]) => rows.map((x) => x.token));
    } else {
      return json({ dilewati: true });
    }

    if (tokens.length === 0) return json({ target, terkirim: 0, catatan: "tidak ada perangkat terdaftar" });

    const sa = loadServiceAccount();
    const accessToken = await getAccessToken(sa);
    const hasil = await Promise.all(
      tokens.map((t) =>
        kirim(sa.project_id, accessToken, t, judul, isi, {
          pesanan_id: String(rec.id),
          tipe: target === "admin" ? "pesanan_baru" : "siap_diambil",
        })
      ),
    );
    return json({ target, perangkat: tokens.length, terkirim: hasil.filter(Boolean).length });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});
