import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'push_stub.dart' if (dart.library.js_interop) 'push_web.dart';

// Dipasang ke MaterialApp agar banner notifikasi bisa tampil dari mana saja.
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum HasilNotifikasi {
  aktif,
  belumDikonfigurasi,
  tidakDidukung,
  ditolak,
  belumDiizinkan,
  gagal,
}

String pesanHasil(HasilNotifikasi h) {
  switch (h) {
    case HasilNotifikasi.aktif:
      return "Notifikasi aktif di perangkat ini";
    case HasilNotifikasi.belumDikonfigurasi:
      return "Firebase belum dikonfigurasi (lihat PANDUAN_NOTIFIKASI.md)";
    case HasilNotifikasi.tidakDidukung:
      return "Browser/perangkat ini belum mendukung push notification";
    case HasilNotifikasi.ditolak:
      return "Izin notifikasi diblokir. Aktifkan lewat pengaturan situs/aplikasi";
    case HasilNotifikasi.belumDiizinkan:
      return "Izin notifikasi belum diberikan";
    case HasilNotifikasi.gagal:
      return "Gagal mengaktifkan notifikasi, coba lagi";
  }
}

// Mendaftarkan perangkat untuk menerima push (FCM) dan menyimpan tokennya
// ke tabel device_tokens di Supabase. Server (Edge Function) memakai tabel
// itu untuk menentukan siapa yang dikirimi notifikasi.
class NotifikasiService {
  NotifikasiService._();
  static final NotifikasiService instance = NotifikasiService._();

  static const _kTokenPref = "fcmToken";

  // Bertambah setiap ada push masuk saat aplikasi terbuka. Layar daftar
  // pesanan memantau ini untuk memuat ulang datanya.
  final ValueNotifier<int> tandaMasuk = ValueNotifier<int>(0);

  bool _androidSiap = false;
  bool _androidListening = false;
  bool _webListening = false;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // minta=false: diam-diam (tanpa memunculkan dialog izin), dipakai saat
  //   aplikasi dibuka kembali. minta=true: boleh meminta izin ke pengguna.
  Future<HasilNotifikasi> daftarkan({bool minta = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId");
      final role = prefs.getString("role");
      if (userId == null || role == null) return HasilNotifikasi.gagal;
      // Admin hanya diberi notifikasi pesanan untuk cabang yang sedang dikelola.
      final cabangId =
          role == "admin" ? int.tryParse(prefs.getString("cabangId") ?? "") : null;

      String? token;
      String platform;

      if (kIsWeb) {
        platform = "web";
        if (!_webListening) {
          _webListening = true;
          PushWeb.dengarkan(_pesanMasuk);
        }
        token = await PushWeb.ambilToken(minta: minta);
        if (token == null) return _dariStatusWeb();
      } else if (_android) {
        platform = "android";
        final (t, hasil) = await _tokenAndroid(minta: minta);
        if (t == null) return hasil;
        token = t;
      } else {
        return HasilNotifikasi.tidakDidukung;
      }

      await _simpanToken(token, userId, role, platform, cabangId);
      await prefs.setString(_kTokenPref, token);
      return HasilNotifikasi.aktif;
    } catch (e) {
      debugPrint("Notifikasi gagal didaftarkan: $e");
      return HasilNotifikasi.gagal;
    }
  }

  // Dipanggil saat logout: hentikan pengiriman push ke perangkat ini
  // agar tidak menerima notifikasi milik akun sebelumnya.
  Future<void> batalkan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kTokenPref);
      if (token == null) return;
      await http.delete(
        Uri.parse(
            "${AppConfig.baseUrl}/device_tokens?token=eq.${Uri.encodeQueryComponent(token)}"),
        headers: AppConfig.headers,
      );
      await prefs.remove(_kTokenPref);
    } catch (e) {
      debugPrint("Gagal membatalkan token: $e");
    }
  }

  HasilNotifikasi _dariStatusWeb() {
    switch (PushWeb.status()) {
      case "belum_dikonfigurasi":
        return HasilNotifikasi.belumDikonfigurasi;
      case "tidak_didukung":
        return HasilNotifikasi.tidakDidukung;
      case "ditolak":
        return HasilNotifikasi.ditolak;
      case "belum_diizinkan":
        return HasilNotifikasi.belumDiizinkan;
      default:
        return HasilNotifikasi.gagal;
    }
  }

  Future<(String?, HasilNotifikasi)> _tokenAndroid({required bool minta}) async {
    if (!_androidSiap) {
      try {
        // Butuh android/app/google-services.json (lihat panduan).
        await Firebase.initializeApp();
        _androidSiap = true;
      } catch (e) {
        debugPrint("Firebase Android belum dikonfigurasi: $e");
        return (null, HasilNotifikasi.belumDikonfigurasi);
      }
    }

    final fm = FirebaseMessaging.instance;
    var izin = await fm.getNotificationSettings();
    if (izin.authorizationStatus == AuthorizationStatus.notDetermined) {
      if (!minta) return (null, HasilNotifikasi.belumDiizinkan);
      izin = await fm.requestPermission();
    }
    if (izin.authorizationStatus == AuthorizationStatus.denied) {
      return (null, HasilNotifikasi.ditolak);
    }

    if (!_androidListening) {
      _androidListening = true;
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        _pesanMasuk(n?.title ?? "", n?.body ?? "");
      });
      fm.onTokenRefresh.listen((baru) async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString("userId");
        final role = prefs.getString("role");
        if (userId == null || role == null) return;
        final cabangId = role == "admin"
            ? int.tryParse(prefs.getString("cabangId") ?? "")
            : null;
        try {
          await _simpanToken(baru, userId, role, "android", cabangId);
          await prefs.setString(_kTokenPref, baru);
        } catch (_) {}
      });
    }

    final token = await fm.getToken();
    return (token, token == null ? HasilNotifikasi.gagal : HasilNotifikasi.aktif);
  }

  // Upsert berdasarkan kolom token: jika perangkat yang sama dipakai akun lain,
  // baris yang ada dipindahkan ke akun yang sedang login.
  Future<void> _simpanToken(String token, String userId, String role,
      String platform, int? cabangId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.baseUrl}/device_tokens?on_conflict=token"),
      headers: {
        ...AppConfig.headers,
        "Prefer": "resolution=merge-duplicates,return=minimal",
      },
      body: jsonEncode({
        "token": token,
        "user_id": int.parse(userId),
        "role": role,
        "platform": platform,
        "cabang_id": cabangId,
        "updated_at": DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (res.statusCode >= 300) {
      throw Exception("Simpan token gagal (${res.statusCode}): ${res.body}");
    }
  }

  // Push masuk saat aplikasi terbuka: tampilkan banner di dalam aplikasi
  // dan beri tanda agar layar daftar pesanan memuat ulang.
  void _pesanMasuk(String judul, String isi) {
    tandaMasuk.value++;
    final m = messengerKey.currentState;
    if (m == null) return;
    m.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (isi.isNotEmpty) Text(isi),
          ],
        ),
      ),
    );
  }
}
