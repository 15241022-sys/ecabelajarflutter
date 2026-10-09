import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/cabang_service.dart';
import '../../services/notifikasi_service.dart';
import '../../services/pesanan_service.dart';
import '../../utils/pesanan_util.dart';
import '../../widgets/produk_card.dart' show formatRupiah;
import '../detail_pesanan_screen.dart';

// Pemantauan pesanan terjadwal (admin).
// Tab "Akan datang" = pesanan terjadwal yang masih diproses, urut terdekat.
// Tab "Selesai" = pesanan terjadwal yang sudah selesai / dibatalkan.
// Data otomatis diperbarui tiap 30 detik, dan bisa tarik-untuk-segarkan.
class ListJadwalScreen extends StatefulWidget {
  const ListJadwalScreen({super.key});

  @override
  State<ListJadwalScreen> createState() => _ListJadwalScreenState();
}

class _ListJadwalScreenState extends State<ListJadwalScreen> {
  final _service = PesananService();
  Timer? _timer;

  List<dynamic> _data = [];
  Object? _error;
  bool _loading = true;
  bool _tabAktif = true;

  @override
  void initState() {
    super.initState();
    _muat();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _muat(senyap: true));
    NotifikasiService.instance.tandaMasuk.addListener(_dariPush);
  }

  void _dariPush() => _muat(senyap: true);

  @override
  void dispose() {
    NotifikasiService.instance.tandaMasuk.removeListener(_dariPush);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _muat({bool senyap = false}) async {
    if (!senyap) setState(() => _loading = true);
    try {
      final data = await _service.getPesananTerjadwal(cabangId: CabangState.instance.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Pada refresh otomatis, pertahankan data lama jika gagal sesaat.
        if (!senyap) _error = e;
        _loading = false;
      });
    }
  }

  // Masih aktif = belum selesai/dibatalkan (termasuk "siap diambil").
  bool _masihAktif(Map<String, dynamic> p) {
    final s = (p["status"] ?? "diproses").toString();
    return s == "diproses" || s == statusSiap;
  }

  String _durasi(int menit) {
    if (menit < 60) return "$menit mnt";
    final jam = menit ~/ 60;
    if (jam >= 24) return "${jam ~/ 24} hari";
    final sisa = menit % 60;
    return sisa == 0 ? "$jam jam" : "$jam jam $sisa mnt";
  }

  // Label sisa waktu + warna: merah jika terlambat, oranye jika < 1 jam.
  (String, Color) _sisaWaktu(DateTime jadwal) {
    final selisih = jadwal.difference(DateTime.now());
    if (selisih.isNegative) {
      return ("Terlambat ${_durasi(-selisih.inMinutes)}", Colors.red);
    }
    final warna = selisih.inMinutes < 60 ? Colors.deepOrange : Colors.green.shade700;
    return ("${_durasi(selisih.inMinutes)} lagi", warna);
  }

  String _judulHari(DateTime d) {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final hariItu = DateTime(d.year, d.month, d.day);
    final beda = hariItu.difference(hariIni).inDays;
    final label = formatHariTanggal(d);
    if (beda == 0) return "Hari ini • $label";
    if (beda == 1) return "Besok • $label";
    if (beda == -1) return "Kemarin • $label";
    return label;
  }

  Future<void> _buka(Map<String, dynamic> p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPesananScreen(pesanan: p, isAdmin: true),
      ),
    );
    _muat(senyap: true);
  }

  Widget _kartu(Map<String, dynamic> p) {
    final jadwal = parseWaktu(p["jadwal_ambil"])!;
    final aktif = _masihAktif(p);
    final status = (p["status"] ?? "diproses").toString();
    final sisa = aktif ? _sisaWaktu(jadwal) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _buka(p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Text("${dua(jadwal.hour)}:${dua(jadwal.minute)}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (sisa != null)
                      Text(sisa.$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: sisa.$2)),
                  ],
                ),
              ),
              const VerticalDivider(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("#${p["id"]}  ${p["users"]?["nama"] ?? "-"}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(formatRupiah(p["total_harga"] ?? 0)),
                    Text(
                      "${labelMetode(p["metode_pembayaran"])}  •  ${labelBayar(p["status_pembayaran"])}",
                      style: TextStyle(
                          fontSize: 12, color: warnaBayar(p["status_pembayaran"])),
                    ),
                  ],
                ),
              ),
              Text(labelStatus(status), style: TextStyle(color: warnaStatus(status))),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _susunDaftar(List<Map<String, dynamic>> list) {
    final widgets = <Widget>[];
    String? kunciTerakhir;
    for (final p in list) {
      final d = parseWaktu(p["jadwal_ambil"]);
      if (d == null) continue;
      final kunci = "${d.year}-${d.month}-${d.day}";
      if (kunci != kunciTerakhir) {
        kunciTerakhir = kunci;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(_judulHari(d),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ));
      }
      widgets.add(_kartu(p));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final semua = _data.cast<Map<String, dynamic>>();
    final aktif = semua.where(_masihAktif).toList(); // sudah urut terdekat
    final selesai = semua.where((p) => !_masihAktif(p)).toList().reversed.toList();
    final tampil = _tabAktif ? aktif : selesai;
    final terlambat = aktif.where((p) {
      final d = parseWaktu(p["jadwal_ambil"]);
      return d != null && d.isBefore(DateTime.now());
    }).length;

    return Scaffold(
      appBar: AppBar(title: Text("Pesanan terjadwal • ${CabangState.instance.nama ?? "-"}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text("Akan datang (${aktif.length})"),
                  selected: _tabAktif,
                  onSelected: (_) => setState(() => _tabAktif = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text("Selesai (${selesai.length})"),
                  selected: !_tabAktif,
                  onSelected: (_) => setState(() => _tabAktif = false),
                ),
              ],
            ),
          ),
          if (_tabAktif && terlambat > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$terlambat pesanan melewati jadwal dan belum selesai",
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _muat,
              child: Builder(builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null) {
                  return ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text("Gagal memuat: $_error")),
                  ]);
                }
                if (tampil.isEmpty) {
                  return ListView(children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text(_tabAktif
                          ? "Tidak ada pesanan terjadwal"
                          : "Belum ada riwayat pesanan terjadwal"),
                    ),
                  ]);
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: _susunDaftar(tampil),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
