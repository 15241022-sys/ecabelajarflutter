import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class KategoriService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Map<String, String> headers = AppConfig.headers;

  // GET kategori (opsional hanya milik satu cabang)
  Future<List<dynamic>> getKategori({int? cabangId}) async {
    final filterCabang = cabangId == null ? "" : "&cabang_id=eq.$cabangId";
    final response = await http.get(
      Uri.parse("$baseUrl/kategori?order=id.asc$filterCabang"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Gagal mengambil data kategori");
  }

  // POST tambah kategori
  Future<bool> tambahKategori(String namaKategori, {required int cabangId}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/kategori"),
      headers: headers,
      body: jsonEncode({"nama_kategori": namaKategori, "cabang_id": cabangId}),
    );
    return response.statusCode == 201;
  }

  // PATCH ubah kategori
  Future<bool> ubahKategori(String id, String namaKategori) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/kategori?id=eq.$id"),
      headers: headers,
      body: jsonEncode({"nama_kategori": namaKategori}),
    );
    return response.statusCode == 200;
  }

  // DELETE hapus kategori
  // Catatan: gagal jika masih ada produk yang memakai kategori ini (foreign key)
  Future<bool> hapusKategori(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/kategori?id=eq.$id"),
      headers: headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
