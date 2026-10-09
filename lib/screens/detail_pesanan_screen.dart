import 'package:flutter/material.dart';
import '../services/pesanan_service.dart';
import '../utils/pesanan_util.dart';

const daftarStatus = ["diproses", "siap_diambil", "selesai", "dibatalkan"];

Color warnaStatus(String status) {
  switch (status) {
    case "siap_diambil":
      return Colors.blue;
    case "selesai":
      return Colors.green;
    case "dibatalkan":
      return Colors.red;
    default:
      return Colors.orange;
  }
}

// Tanggal pesanan, ditampilkan dalam zona waktu perangkat.
String formatTanggal(dynamic tanggal) {
  final d = parseWaktu(tanggal);
  if (d == null) return tanggal == null ? "-" : tanggal.toString();
  return "${d.year}-${dua(d.month)}-${dua(d.day)} ${dua(d.hour)}:${dua(d.minute)}";
}

// Dipakai bersama oleh member (lihat saja) dan admin (bisa ubah status)
class DetailPesananScreen extends StatefulWidget {
  final Map<String, dynamic> pesanan;
  final bool isAdmin;
  const DetailPesananScreen({
    super.key,
    required this.pesanan,
    this.isAdmin = false,
  });

  @override
  State<DetailPesananScreen> createState() => _DetailPesananScreenState();
}

class _DetailPesananScreenState extends State<DetailPesananScreen> {
  final _service = PesananService();
  late Future<List<dynamic>> _detailFuture;
  late String _status;
  late String _statusBayar;

  @override
  void initState() {
    super.initState();
    _status = widget.pesanan["status"] ?? "diproses";
    _statusBayar = widget.pesanan["status_pembayaran"] ?? bayarBelum;
    _detailFuture = _service.getDetailPesanan(widget.pesanan["id"].toString());
  }

  Future<void> _ubahStatus(String? baru) async {
    if (baru == null || baru == _status) return;
    final ok = await _service.updateStatus(widget.pesanan["id"].toString(), baru);
    if (!mounted) return;
    if (ok) {
      setState(() => _status = baru);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "Status diperbarui" : "Gagal memperbarui status")),
    );
  }

  Future<void> _ubahBayar(String? baru) async {
    if (baru == null || baru == _statusBayar) return;
    final ok = await _service.updateStatusPembayaran(
        widget.pesanan["id"].toString(), baru);
    if (!mounted) return;
    if (ok) {
      setState(() => _statusBayar = baru);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? "Status pembayaran diperbarui" : "Gagal memperbarui pembayaran")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pesanan;
    return Scaffold(
      appBar: AppBar(title: Text("Pesanan #${p["id"]}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p["users"] != null) Text("Pemesan: ${p["users"]["nama"]}"),
            Text("Tanggal: ${formatTanggal(p["tanggal"])}"),
            if (p["cabang"] != null) Text("Outlet: ${p["cabang"]["nama"]}"),
            if (p["jadwal_ambil"] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Jadwal ambil: ${formatJadwal(p["jadwal_ambil"])}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text("Pembayaran: ${labelMetode(p["metode_pembayaran"])}"),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Status: "),
                if (widget.isAdmin)
                  DropdownButton<String>(
                    value: _status,
                    items: daftarStatus
                        .map((s) => DropdownMenuItem(value: s, child: Text(labelStatus(s))))
                        .toList(),
                    onChanged: _ubahStatus,
                  )
                else
                  Chip(
                    label: Text(labelStatus(_status)),
                    backgroundColor: warnaStatus(_status).withOpacity(0.15),
                  ),
              ],
            ),
            Row(
              children: [
                const Text("Pembayaran: "),
                if (widget.isAdmin)
                  DropdownButton<String>(
                    value: _statusBayar,
                    items: [bayarBelum, bayarLunas]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(labelBayar(s))))
                        .toList(),
                    onChanged: _ubahBayar,
                  )
                else
                  Chip(
                    label: Text(labelBayar(_statusBayar)),
                    backgroundColor: warnaBayar(_statusBayar).withOpacity(0.15),
                  ),
              ],
            ),
            const Divider(),
            const Text("Item pesanan",
                style: TextStyle(fontWeight: FontWeight.w600)),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Gagal memuat: ${snapshot.error}"));
                  }
                  final items = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final d = items[i];
                      final nama = d["produk"]?["nama_produk"] ?? "Produk #${d["produk_id"]}";
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(nama),
                        subtitle: Text("${d["qty"]} x"),
                        trailing: Text("Rp${d["subtotal"]}"),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Text("Total: Rp${p["total_harga"]}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
