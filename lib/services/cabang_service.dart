import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

// Daftar cabang outlet (tabel "cabang" di Supabase).
class CabangService {
  static List<dynamic>? _cache;

  Future<List<dynamic>> getCabang({bool paksa = false}) async {
    if (_cache != null && !paksa) return _cache!;
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/cabang?aktif=eq.true&order=id.asc"),
      headers: AppConfig.headers,
    );
    if (res.statusCode == 200) {
      _cache = jsonDecode(res.body) as List<dynamic>;
      return _cache!;
    }
    throw Exception("Gagal mengambil daftar cabang (${res.statusCode})");
  }
}

// Cabang yang sedang dipilih pada sesi ini.
//  - Member: outlet tempat mengambil pesanan (menu mengikuti outlet ini).
//  - Admin : cabang yang sedang dikelola (produk, kategori, pesanan).
// Disimpan di SharedPreferences agar bertahan saat aplikasi dibuka ulang,
// dan ikut terhapus saat logout (prefs.clear()).
class CabangState extends ChangeNotifier {
  CabangState._();
  static final CabangState instance = CabangState._();

  static const _kId = "cabangId";
  static const _kNama = "cabangNama";

  int? _id;
  String? _nama;

  int? get id => _id;
  String? get nama => _nama;
  bool get terpilih => _id != null;

  Future<void> muat() async {
    final prefs = await SharedPreferences.getInstance();
    _id = int.tryParse(prefs.getString(_kId) ?? "");
    _nama = _id == null ? null : prefs.getString(_kNama);
    notifyListeners();
  }

  Future<void> pilih(int id, String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, id.toString());
    await prefs.setString(_kNama, nama);
    _id = id;
    _nama = nama;
    notifyListeners();
  }

  // Dipanggil saat logout (prefs sudah dibersihkan oleh AuthService).
  void reset() {
    _id = null;
    _nama = null;
    notifyListeners();
  }
}
