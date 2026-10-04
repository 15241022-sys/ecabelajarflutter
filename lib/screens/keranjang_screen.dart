import 'package:flutter/material.dart';
import '../config.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/pesanan_service.dart';
import '../utils/pesanan_util.dart';
import 'qris_screen.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final _cart = CartService.instance;
  bool _loading = false;

  // Opsi checkout
  String _metode = metodeCash; // "cash" / "qris"
  bool _jadwalkan = false; // false = ambil sekarang
  DateTime? _jadwal;

  Future<void> _pilihJadwal() async {
    final sekarang = DateTime.now();
    final minimal = sekarang.add(AppConfig.jedaMinimalJadwal);

    final tgl = await showDatePicker(
      context: context,
      initialDate: _jadwal ?? minimal,
      firstDate: DateTime(sekarang.year, sekarang.month, sekarang.day),
      lastDate: sekarang.add(Duration(days: AppConfig.maksHariJadwal)),
      helpText: "Pilih tanggal ambil",
    );
    if (tgl == null || !mounted) return;

    final jam = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_jadwal ?? minimal),
      helpText: "Pilih jam ambil",
    );
    if (jam == null || !mounted) return;

    final dipilih = DateTime(tgl.year, tgl.month, tgl.day, jam.hour, jam.minute);
    if (dipilih.isBefore(minimal)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Jadwal minimal ${AppConfig.jedaMinimalJadwal.inMinutes} menit dari sekarang"),
      ));
      return;
    }
    setState(() => _jadwal = dipilih);
  }

  Future<void> _checkout() async {
    if (_jadwalkan) {
      if (_jadwal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih tanggal dan jam pengambilan")),
        );
        return;
      }
      // Cek ulang: jadwal bisa jadi sudah lewat jika layar dibiarkan lama.
      if (_jadwal!.isBefore(DateTime.now().add(AppConfig.jedaMinimalJadwal))) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Jadwal minimal ${AppConfig.jedaMinimalJadwal.inMinutes} menit dari sekarang, pilih ulang"),
        ));
        return;
      }
    }

    setState(() => _loading = true);

    final userId = await AuthService().getUserId();
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final items = _cart.items
        .map((i) => {
              "produk_id": i.produk["id"],
              "qty": i.qty,
              "subtotal": i.subtotal,
            })
        .toList();

    final total = _cart.totalHarga;
    final jadwal = _jadwalkan ? _jadwal : null;

    final pesananId = await PesananService().buatPesanan(
      userId: userId,
      totalHarga: total,
      items: items,
      metodePembayaran: _metode,
      jadwalAmbil: jadwal,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (pesananId != null) {
      _cart.kosongkan();
      if (_metode == metodeQris) {
        // Tampilkan QRIS; saat ditutup kembali ke menu.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QrisScreen(
              pesananId: pesananId,
              total: total,
              jadwal: jadwal,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jadwal == null
                ? "Pesanan dibuat. Silakan bayar di kasir."
                : "Pesanan terjadwal. Bayar di kasir saat mengambil."),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout gagal, coba lagi")),
      );
    }
  }

  Widget _panelOpsi() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text("Metode pembayaran",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: metodeCash,
                  icon: Icon(Icons.point_of_sale),
                  label: Text("Cash di kasir"),
                ),
                ButtonSegment(
                  value: metodeQris,
                  icon: Icon(Icons.qr_code_2),
                  label: Text("QRIS"),
                ),
              ],
              selected: {_metode},
              onSelectionChanged: (v) => setState(() => _metode = v.first),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Waktu pengambilan",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.flash_on),
                  label: Text("Sekarang"),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.event),
                  label: Text("Jadwalkan"),
                ),
              ],
              selected: {_jadwalkan},
              onSelectionChanged: (v) {
                setState(() => _jadwalkan = v.first);
                if (_jadwalkan && _jadwal == null) _pilihJadwal();
              },
            ),
          ),
          if (_jadwalkan) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(_jadwal == null
                    ? "Belum dipilih"
                    : formatJadwal(_jadwal!.toIso8601String())),
                subtitle: Text(
                    "Min. ${AppConfig.jedaMinimalJadwal.inMinutes} menit dari sekarang, "
                    "maks. ${AppConfig.maksHariJadwal} hari ke depan"),
                trailing: TextButton(
                  onPressed: _pilihJadwal,
                  child: Text(_jadwal == null ? "Pilih" : "Ubah"),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: ListenableBuilder(
        listenable: _cart,
        builder: (context, _) {
          if (_cart.isEmpty) {
            return const Center(child: Text("Keranjang masih kosong"));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _cart.items.length + 1, // +1 = panel opsi
                  itemBuilder: (context, index) {
                    if (index == _cart.items.length) return _panelOpsi();
                    final item = _cart.items[index];
                    final id = item.produk["id"] as int;
                    return ListTile(
                      title: Text(item.produk["nama_produk"] ?? "-"),
                      subtitle: Text("Rp${item.harga} x ${item.qty} = Rp${item.subtotal}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _cart.ubahQty(id, item.qty - 1),
                          ),
                          Text("${item.qty}"),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _cart.ubahQty(id, item.qty + 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Total: Rp${_cart.totalHarga}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      onPressed: _loading ? null : _checkout,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
