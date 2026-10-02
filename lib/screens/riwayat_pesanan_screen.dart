import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/pesanan_service.dart';
import 'detail_pesanan_screen.dart';

class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({super.key});

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _muat();
  }

  Future<List<dynamic>> _muat() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return [];
    return PesananService().getPesananUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat pesanan")),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _muat()),
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
                  title: Text("Pesanan #${p["id"]}  •  Rp${p["total_harga"]}"),
                  subtitle: Text(formatTanggal(p["tanggal"])),
                  trailing: Text(status,
                      style: TextStyle(color: warnaStatus(status))),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPesananScreen(pesanan: p),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
