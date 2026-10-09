import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cabang_service.dart';
import '../services/notifikasi_service.dart';
import '../widgets/tombol_notifikasi.dart';
import 'login_screen.dart';
import 'admin/list_jadwal_screen.dart';
import 'admin/list_kategori_screen.dart';
import 'admin/list_pesanan_screen.dart';
import 'admin/list_produk_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _cabang = CabangState.instance;
  late Future<List<dynamic>> _cabangFuture;

  @override
  void initState() {
    super.initState();
    _cabangFuture = CabangService().getCabang();
  }

  Future<void> _pilih(Map<String, dynamic> c) async {
    await _cabang.pilih((c["id"] as num).toInt(), c["nama"].toString());
    if (!mounted) return;
    setState(() {});
    // Perbarui cabang pada token push perangkat ini (diam-diam), agar
    // notifikasi pesanan baru hanya datang dari cabang yang sedang dikelola.
    unawaited(NotifikasiService.instance.daftarkan());
  }

  Widget _kartuCabang() {
    final terpilih = _cabang.terpilih;
    return Card(
      color: terpilih ? null : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    terpilih
                        ? "Cabang aktif: ${_cabang.nama}"
                        : "Pilih cabang terlebih dahulu",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (!terpilih) ...[
              const SizedBox(height: 4),
              const Text(
                  "Pilih salah satu cabang untuk membuka kelola produk, kategori, dan pesanan."),
            ],
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _cabangFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Row(
                    children: [
                      const Expanded(child: Text("Gagal memuat daftar cabang")),
                      TextButton(
                        onPressed: () => setState(() => _cabangFuture =
                            CabangService().getCabang(paksa: true)),
                        child: const Text("Coba lagi"),
                      ),
                    ],
                  );
                }
                final daftar = snapshot.data ?? [];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daftar.map((c) {
                    final data = c as Map<String, dynamic>;
                    final id = (data["id"] as num).toInt();
                    return ChoiceChip(
                      label: Text(data["nama"].toString()),
                      selected: _cabang.id == id,
                      onSelected: (_) => _pilih(data),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(IconData icon, String judul, Widget Function() tujuan) {
    final aktif = _cabang.terpilih;
    return Opacity(
      opacity: aktif ? 1 : 0.4,
      child: Card(
        child: ListTile(
          leading: Icon(icon, size: 32),
          title: Text(judul),
          trailing: Icon(aktif ? Icons.chevron_right : Icons.lock_outline),
          onTap: () {
            if (!aktif) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pilih cabang terlebih dahulu")),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => tujuan()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard admin"),
        actions: [
          const TombolNotifikasi(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _kartuCabang(),
          const SizedBox(height: 8),
          _menuCard(Icons.local_cafe, "Kelola produk", () => const ListProdukScreen()),
          _menuCard(Icons.category, "Kelola kategori", () => const ListKategoriScreen()),
          _menuCard(Icons.receipt_long, "Pesanan masuk", () => const ListPesananScreen()),
          _menuCard(Icons.event_note, "Pesanan terjadwal", () => const ListJadwalScreen()),
        ],
      ),
    );
  }
}
