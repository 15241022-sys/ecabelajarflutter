import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProdukService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Map<String, String> headers = AppConfig.headers;

  // GET semua produk (opsional filter per kategori)
  Future<List<dynamic>> getProduk({String? kategoriId}) async {
    final response =
        await http.get(Uri.parse("$baseUrl/produk"), headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (kategoriId != null) {
        return data.where((p) => p["kategori_id"].toString() == kategoriId).toList();
      }
      return data;
    }
    throw Exception("Gagal mengambil data produk");
  }

  // GET detail satu produk
  Future<Map<String, dynamic>> getDetailProduk(String id) async {
    final response =
        await http.get(Uri.parse("$baseUrl/produk?id=eq.$id"), headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isEmpty) throw Exception("Produk tidak ditemukan");
      return data.first;
    }
    throw Exception("Produk tidak ditemukan");
  }

  // POST tambah produk baru (dipakai halaman admin)
  Future<bool> tambahProduk({
    required String kategoriId,
    required String namaProduk,
    required int harga,
    required String deskripsi,
    required String gambar,
    required int stok,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/produk"),
      headers: headers,
      body: jsonEncode({
        "kategori_id": int.tryParse(kategoriId) ?? kategoriId,
        "nama_produk": namaProduk,
        "harga": harga,
        "deskripsi": deskripsi,
        "gambar": gambar,
        "stok": stok,
      }),
    );
    return response.statusCode == 201;
  }

  // PUT ubah data produk
  Future<bool> ubahProduk({
    required String id,
    required String kategoriId,
    required String namaProduk,
    required int harga,
    required String deskripsi,
    required String gambar,
    required int stok,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/produk?id=eq.$id"),
      headers: headers,
      body: jsonEncode({
        "kategori_id": int.tryParse(kategoriId) ?? kategoriId,
        "nama_produk": namaProduk,
        "harga": harga,
        "deskripsi": deskripsi,
        "gambar": gambar,
        "stok": stok,
      }),
    );
    return response.statusCode == 200;
  }

  // DELETE hapus produk
  Future<bool> hapusProduk(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/produk?id=eq.$id"),
      headers: headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
