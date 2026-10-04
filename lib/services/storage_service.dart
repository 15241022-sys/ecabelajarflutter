import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';

// Upload file ke Supabase Storage (bucket publik "produk").
// Memakai bytes (bukan File/path) supaya jalan di Android, web, dan desktop.
class StorageService {
  static const _ekstensiDiizinkan = ["jpg", "jpeg", "png", "webp", "gif"];

  String _ekstensi(String namaFile) {
    final i = namaFile.lastIndexOf(".");
    if (i < 0) return "jpg";
    final ext = namaFile.substring(i + 1).toLowerCase();
    return _ekstensiDiizinkan.contains(ext) ? ext : "jpg";
  }

  String _mime(String ext) {
    switch (ext) {
      case "png":
        return "image/png";
      case "webp":
        return "image/webp";
      case "gif":
        return "image/gif";
      default:
        return "image/jpeg";
    }
  }

  // Mengembalikan URL publik gambar yang bisa langsung disimpan
  // ke kolom produk.gambar. Melempar Exception jika gagal.
  Future<String> uploadGambarProduk({
    required Uint8List bytes,
    required String namaFile,
  }) async {
    final ext = _ekstensi(namaFile);
    // Nama unik supaya tidak menimpa gambar lain dan tidak kena cache lama.
    final path = "produk_${DateTime.now().millisecondsSinceEpoch}.$ext";

    final res = await http.post(
      Uri.parse(
          "${AppConfig.storageUrl}/object/${AppConfig.bucketProduk}/$path"),
      headers: {
        "apikey": AppConfig.apiKey,
        "Content-Type": _mime(ext),
      },
      body: bytes,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return "${AppConfig.storageUrl}/object/public/${AppConfig.bucketProduk}/$path";
    }
    throw Exception("Upload gambar gagal (${res.statusCode}): ${res.body}");
  }
}
