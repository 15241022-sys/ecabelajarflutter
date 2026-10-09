import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cabang_service.dart';
import '../services/notifikasi_service.dart';
import '../services/pesanan_service.dart';
import '../utils/filter_pesanan.dart';
import '../utils/pesanan_util.dart';
import '../widgets/filter_riwayat_bar.dart';
import 'detail_pesanan_screen.dart';

class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({super.key});

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  // Member: bawaan semua waktu & semua cabang.
  static const _awal = FilterPesanan();

  late Future<List<dynamic>> _future;
  FilterPesanan _filter = _awal;
  List<dynamic> _cabang = [];

  @override
  void initState() {
    super.initState();
    _future = _muat();
    _muatCabang();
    // Muat ulang otomatis saat ada push masuk (mis. pesanan siap diambil).
    NotifikasiService.instance.tandaMasuk.addListener(_muatUlang);
  }

  @override
  void dispose() {
    NotifikasiService.instance.tandaMasuk.removeListener(_muatUlang);
    super.dispose();
  }

  Future<void> _muatCabang() async {
    try {
      final data = await CabangService().getCabang();
      if (mounted) setState(() => _cabang = data);
    } catch (_) {
      // Filter cabang tidak tersedia; daftar pesanan tetap bisa dipakai.
    }
  }

  void _muatUlang() => setState(() => _future = _muat());

  void _ubahFilter(FilterPesanan f) {
    _filter = f;
    _muatUlang();
  }

  Future<List<dynamic>> _muat() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return [];
    return PesananService().getPesananUser(userId, filter: _filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat pesanan")),
      body: Column(
        children: [
          FilterRiwayatBar(
            filter: _filter,
            awal: _awal,
            daftarCabang: _cabang,
            onChanged: _ubahFilter,
          ),
          Expanded(
            child: RefreshIndicator(
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
                    return ListView(children: [
                      const SizedBox(height: 160),
                      Center(
                        child: Text(_filter.sama(_awal)
                            ? "Belum ada pesanan"
                            : "Tidak ada pesanan pada filter ini"),
                      ),
                    ]);
                  }
                  return ListView.builder(
                    itemCount: data.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text("${data.length} pesanan",
                              style: Theme.of(context).textTheme.bodySmall),
                        );
                      }
                      final p = data[i - 1] as Map<String, dynamic>;
                      final status = p["status"] ?? "diproses";
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "Pesanan #${p["id"]}  •  Rp${p["total_harga"]}"),
                            isThreeLine: true,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatTanggal(p["tanggal"])),
                                Text("Outlet ${p["cabang"]?["nama"] ?? "-"}"),
                                if (p["jadwal_ambil"] != null)
                                  Text(
                                      "Jadwal ambil: ${formatJadwal(p["jadwal_ambil"])}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                Text(
                                  "${labelMetode(p["metode_pembayaran"])}  •  ${labelBayar(p["status_pembayaran"])}",
                                  style: TextStyle(
                                      color: warnaBayar(p["status_pembayaran"])),
                                ),
                              ],
                            ),
                            trailing: Text(labelStatus(status),
                                style: TextStyle(color: warnaStatus(status))),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPesananScreen(pesanan: p),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
