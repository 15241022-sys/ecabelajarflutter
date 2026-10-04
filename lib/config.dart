// Konfigurasi terpusat untuk koneksi ke Supabase.
// Cukup ubah di sini, semua service otomatis ikut.
class AppConfig {
  static const String supabaseUrl = "https://wkvslpzukeguniatcctz.supabase.co";
  static const String baseUrl = "$supabaseUrl/rest/v1";

  // Supabase Storage untuk menyimpan foto produk.
  // Bucket "produk" harus dibuat dulu (lihat supabase_migration.sql).
  static const String storageUrl = "$supabaseUrl/storage/v1";
  static const String bucketProduk = "produk";

  // Aturan jadwal pemesanan member.
  static const Duration jedaMinimalJadwal = Duration(minutes: 30);
  static const int maksHariJadwal = 7;

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
