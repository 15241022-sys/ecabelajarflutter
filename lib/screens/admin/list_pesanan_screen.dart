import 'package:flutter/material.dart';
import '../../services/pesanan_service.dart';
import '../../utils/pesanan_util.dart';
import '../detail_pesanan_screen.dart';

class ListPesananScreen extends StatefulWidget {
  const ListPesananScreen({super.key});

  @override
  State<ListPesananScreen> createState() => _ListPesananScreenState();
}

class _ListPesananScreenState extends State<ListPesananScreen> {
  final _service = PesananService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSemuaPesanan();
  }

  void _muatUlang() => setState(() => _future = _service.getSemuaPesanan());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesanan masuk")),
      body: RefreshIndicator(
        onRefresh: () async => _muatUlang(),
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Gagal memuat: ${snapshot.error}"));
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 200),
                Center(child: Text("Belum ada pesanan")),
              ]);
            }
            return ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = data[i] as Map<String, dynamic>;
                final status = p["status"] ?? "diproses";
                return ListTile(
                  title: Text("#${p["id"]}  ${p["users"]?["nama"] ?? "-"}"),
                  isThreeLine: true,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${formatTanggal(p["tanggal"])}  •  Rp${p["total_harga"]}"),
                      Text(
                        "${labelMetode(p["metode_pembayaran"])}  •  ${labelBayar(p["status_pembayaran"])}",
                        style: TextStyle(color: warnaBayar(p["status_pembayaran"])),
                      ),
                      if (p["jadwal_ambil"] != null)
                        Text("Jadwal: ${formatJadwal(p["jadwal_ambil"])}",
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  trailing: Text(status, style: TextStyle(color: warnaStatus(status))),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPesananScreen(pesanan: p, isAdmin: true),
                      ),
                    );
                    _muatUlang(); // segarkan status setelah kembali
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
