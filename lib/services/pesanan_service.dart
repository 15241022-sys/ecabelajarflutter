import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class PesananService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Map<String, String> headers = AppConfig.headers;

  // CHECKOUT (member): buat 1 pesanan + banyak detail_pesanan
  // items: [{"produk_id": 1, "qty": 2, "subtotal": 50000}, ...]
  Future<bool> buatPesanan({
    required String userId,
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    // 1. Simpan pesanan utama
    final res = await http.post(
      Uri.parse("$baseUrl/pesanan"),
      headers: headers,
      body: jsonEncode({
        "user_id": int.parse(userId),
        "status": "diproses",
        "total_harga": totalHarga,
      }),
    );
    if (res.statusCode != 201) return false;

    // Supabase mengembalikan array berisi baris yang baru dibuat
    final pesananId = (jsonDecode(res.body) as List).first["id"];

    // 2. Simpan semua detail sekaligus (bulk insert)
    final detail = items
        .map((item) => {
              "pesanan_id": pesananId,
              "produk_id": item["produk_id"],
              "qty": item["qty"],
              "subtotal": item["subtotal"],
            })
        .toList();

    final resDetail = await http.post(
      Uri.parse("$baseUrl/detail_pesanan"),
      headers: headers,
      body: jsonEncode(detail),
    );
    return resDetail.statusCode == 201;
  }

  // Riwayat pesanan milik satu member
  Future<List<dynamic>> getPesananUser(String userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/pesanan?user_id=eq.$userId&order=id.desc"),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal mengambil riwayat pesanan");
  }

  // Semua pesanan (admin), sekaligus ambil nama pemesan lewat relasi users
  Future<List<dynamic>> getSemuaPesanan() async {
    final res = await http.get(
      Uri.parse("$baseUrl/pesanan?select=*,users(nama)&order=id.desc"),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal mengambil data pesanan");
  }

  // Detail item dalam satu pesanan, sekaligus nama produknya
  Future<List<dynamic>> getDetailPesanan(String pesananId) async {
    final res = await http.get(
      Uri.parse(
          "$baseUrl/detail_pesanan?pesanan_id=eq.$pesananId&select=*,produk(nama_produk,harga)"),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal mengambil detail pesanan");
  }

  // Update status (admin): "diproses" / "selesai" / "dibatalkan"
  Future<bool> updateStatus(String pesananId, String status) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/pesanan?id=eq.$pesananId"),
      headers: headers,
      body: jsonEncode({"status": status}),
    );
    return res.statusCode == 200;
  }
}
