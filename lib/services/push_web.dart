import 'dart:js_interop';

// Jembatan ke window.ecaPush yang didefinisikan di web/push.js.
@JS('ecaPush')
external _EcaPush? get _ecaPush;

extension type _EcaPush._(JSObject _) implements JSObject {
  external JSString status();
  external JSPromise<JSString?> getToken(JSBoolean minta);
  external set onMessage(JSFunction? fn);
}

class PushWeb {
  // "ok" | "belum_dikonfigurasi" | "tidak_didukung" | "ditolak" | "belum_diizinkan"
  static String status() => _ecaPush?.status().toDart ?? "tidak_didukung";

  // Mengembalikan token FCM, atau null jika izin/konfigurasi belum siap.
  static Future<String?> ambilToken({required bool minta}) async {
    final push = _ecaPush;
    if (push == null) return null;
    try {
      final hasil = await push.getToken(minta.toJS).toDart;
      return hasil?.toDart;
    } catch (_) {
      return null;
    }
  }

  // Dipanggil saat ada push masuk ketika aplikasi sedang terbuka.
  static void dengarkan(void Function(String judul, String isi) onPesan) {
    final push = _ecaPush;
    if (push == null) return;
    void handler(JSString judul, JSString isi) =>
        onPesan(judul.toDart, isi.toDart);
    push.onMessage = handler.toJS;
  }
}
