import 'package:flutter/material.dart';
import '../utils/pesanan_util.dart';
import '../widgets/produk_card.dart' show formatRupiah;

// Ditampilkan setelah checkout dengan metode QRIS.
// QRIS toko bersifat statis (gambar di assets/images/qris.png),
// jadi pembayaran dikonfirmasi manual oleh admin/kasir.
class QrisScreen extends StatelessWidget {
  final int pesananId;
  final int total;
  final DateTime? jadwal;

  const QrisScreen({
    super.key,
    required this.pesananId,
    required this.total,
    this.jadwal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bayar dengan QRIS")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Pesanan #$pesananId berhasil dibuat",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (jadwal != null) ...[
              const SizedBox(height: 4),
              Text("Jadwal ambil: ${formatJadwal(jadwal!.toIso8601String())}"),
            ],
            const SizedBox(height: 16),
            Text(formatRupiah(total),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade100),
              ),
              child: Image.asset(
                "assets/images/qris.png",
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("Gambar QRIS belum tersedia"),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Scan kode QR di atas dengan aplikasi e-wallet atau mobile banking, "
              "bayar sesuai total, lalu tunjukkan bukti pembayaran ke kasir. "
              "Status pembayaran akan diperbarui oleh admin setelah diverifikasi.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Selesai"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
