// Implementasi kosong untuk platform non-web (Android memakai firebase_messaging).
class PushWeb {
  static String status() => "tidak_didukung";

  static Future<String?> ambilToken({required bool minta}) async => null;

  static void dengarkan(void Function(String judul, String isi) onPesan) {}
}
