import 'package:flutter/material.dart';
import '../../services/cabang_service.dart';
import '../../services/notifikasi_service.dart';
import '../../services/pesanan_service.dart';
import '../../utils/filter_pesanan.dart';
import '../../utils/pesanan_util.dart';
import '../../widgets/filter_riwayat_bar.dart';
import '../detail_pesanan_screen.dart';

// Pesanan masuk + riwayat (admin). Bawaan: cabang yang sedang dikelola,
// semua waktu. Filter bisa diganti ke cabang lain / semua cabang.
class ListPesananScreen extends StatefulWidget {
  const ListPesananScreen({super.key});

  @override
  State<ListPesananScreen> createState() => _ListPesananScreenState();
}

class _ListPesananScreenState extends State<ListPesananScreen> {
  final _service = PesananService();
  late final FilterPesanan _awal;
  late FilterPesanan _filter;
  late Future<List<dynamic>> _future;
  List<dynamic> _cabang = [];

  @override
  void initState() {
    super.initState();
    _awal = FilterPesanan(
      cabangId: CabangState.instance.id,
      cabangNama: CabangState.instance.nama,
    );
    _filter = _awal;
    _future = _service.getSemuaPesanan(filter: _filter);
    _muatCabang();
    // Muat ulang otomatis saat ada push masuk (pesanan baru).
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

  void _muatUlang() =>
      setState(() => _future = _service.getSemuaPesanan(filter: _filter));

  void _ubahFilter(FilterPesanan f) {
    _filter = f;
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesanan masuk")),
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
                                "#${p["id"]}  ${p["users"]?["nama"] ?? "-"}"),
                            isThreeLine: true,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${formatTanggal(p["tanggal"])}  •  Rp${p["total_harga"]}"),
                                Text("Outlet ${p["cabang"]?["nama"] ?? "-"}"),
                                Text(
                                  "${labelMetode(p["metode_pembayaran"])}  •  ${labelBayar(p["status_pembayaran"])}",
                                  style: TextStyle(
                                      color: warnaBayar(p["status_pembayaran"])),
                                ),
                                if (p["jadwal_ambil"] != null)
                                  Text(
                                      "Jadwal: ${formatJadwal(p["jadwal_ambil"])}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                              ],
                            ),
                            trailing: Text(labelStatus(status),
                                style: TextStyle(color: warnaStatus(status))),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPesananScreen(
                                      pesanan: p, isAdmin: true),
                                ),
                              );
                              _muatUlang(); // segarkan status setelah kembali
                            },
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
