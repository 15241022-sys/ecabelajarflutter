// Konfigurasi terpusat untuk koneksi ke Supabase.
// Cukup ubah di sini, semua service otomatis ikut.
class AppConfig {
  static const String baseUrl =
      "https://wkvslpzukeguniatcctz.supabase.co/rest/v1";

  // Publishable key aman dipakai di aplikasi (client).
  // JANGAN pernah memakai/membagikan "secret key" di aplikasi.
  static const String apiKey =
      "sb_publishable_hF65TBzynv4AmTyN-tqBIQ_QLInTvfI";

  // Catatan: key format baru (sb_publishable_...) bukan JWT,
  // jadi cukup dikirim lewat header "apikey" (tanpa Authorization Bearer).
  static const Map<String, String> headers = {
    "apikey": apiKey,
    "Content-Type": "application/json",
    "Prefer": "return=representation",
  };
}
