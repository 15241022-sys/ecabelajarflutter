// Jembatan antara Flutter (Dart) dan Firebase Cloud Messaging untuk web.
// Dipakai lewat window.ecaPush dari lib/services/push_web.dart.
(function () {
  var listening = false;

  function configured() {
    var c = self.ECA_FIREBASE_CONFIG;
    return !!(c && c.apiKey && String(c.apiKey).indexOf('GANTI') !== 0 &&
      self.ECA_VAPID_KEY && String(self.ECA_VAPID_KEY).indexOf('GANTI') !== 0);
  }

  function supported() {
    try {
      return !!(window.firebase && firebase.messaging && firebase.messaging.isSupported() &&
        'serviceWorker' in navigator && 'Notification' in window);
    } catch (e) { return false; }
  }

  function waitActive(reg) {
    return new Promise(function (resolve) {
      if (reg.active) return resolve();
      var sw = reg.installing || reg.waiting;
      if (!sw) return resolve();
      sw.addEventListener('statechange', function () {
        if (sw.state === 'activated') resolve();
      });
    });
  }

  window.ecaPush = {
    // Diisi oleh Dart: function(judul, isi) dipanggil saat pesan masuk ketika aplikasi terbuka.
    onMessage: null,

    // "ok" | "belum_dikonfigurasi" | "tidak_didukung" | "ditolak" | "belum_diizinkan"
    status: function () {
      if (!configured()) return 'belum_dikonfigurasi';
      if (!supported()) return 'tidak_didukung';
      if (Notification.permission === 'denied') return 'ditolak';
      if (Notification.permission === 'default') return 'belum_diizinkan';
      return 'ok';
    },

    // minta=true: boleh memunculkan dialog izin notifikasi browser.
    getToken: async function (minta) {
      try {
        var s = window.ecaPush.status();
        if (s === 'belum_diizinkan' && minta) {
          var izin = await Notification.requestPermission();
          if (izin !== 'granted') return null;
        } else if (s !== 'ok') {
          return null;
        }

        if (!firebase.apps.length) firebase.initializeApp(self.ECA_FIREBASE_CONFIG);

        // Daftarkan SW secara manual di dalam base-href (penting untuk GitHub Pages
        // yang berada di sub-folder /nama-repo/). Scope harus berada di dalam folder SW.
        var reg = await navigator.serviceWorker.register('firebase-messaging-sw.js', {
          scope: 'firebase-cloud-messaging-push-scope',
        });
        await Promise.race([
          waitActive(reg),
          new Promise(function (r) { setTimeout(r, 10000); }),
        ]);

        var messaging = firebase.messaging();
        if (!listening) {
          listening = true;
          messaging.onMessage(function (payload) {
            var n = (payload && payload.notification) || {};
            if (window.ecaPush.onMessage) window.ecaPush.onMessage(n.title || '', n.body || '');
          });
        }
        return await messaging.getToken({
          vapidKey: self.ECA_VAPID_KEY,
          serviceWorkerRegistration: reg,
        });
      } catch (e) {
        console.error('[ecaPush] gagal mengambil token:', e);
        return null;
      }
    },
  };
})();
