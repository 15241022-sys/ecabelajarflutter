// Service worker untuk menerima push saat aplikasi/tab ditutup.
// Dimuat dari <base-href>/firebase-messaging-sw.js (didaftarkan oleh push.js).
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');
importScripts('firebase-config.js');

self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });

var cfg = self.ECA_FIREBASE_CONFIG;
if (cfg && String(cfg.apiKey).indexOf('GANTI') !== 0) {
  firebase.initializeApp(cfg);
  // Pesan berisi payload "notification" otomatis ditampilkan oleh SDK saat
  // aplikasi tidak sedang dibuka; klik notifikasi membuka link dari server.
  firebase.messaging();
}
