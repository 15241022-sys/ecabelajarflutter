import 'package:flutter/material.dart';
import '../utils/filter_pesanan.dart';

// Baris filter untuk riwayat pesanan (member & admin): waktu + cabang.
class FilterRiwayatBar extends StatelessWidget {
  final FilterPesanan filter;
  final FilterPesanan awal; // nilai bawaan, dipakai tombol "Reset"
  final List<dynamic> daftarCabang;
  final ValueChanged<FilterPesanan> onChanged;

  const FilterRiwayatBar({
    super.key,
    required this.filter,
    required this.awal,
    required this.daftarCabang,
    required this.onChanged,
  });

  Future<void> _pilihWaktu(BuildContext context) async {
    final pilihan = await showModalBottomSheet<RentangWaktu>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Waktu pemesanan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            ...RentangWaktu.values.map(
              (w) => ListTile(
                title: Text(labelRentang(w)),
                trailing: w == filter.waktu
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, w),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (pilihan == null || !context.mounted) return;

    if (pilihan == RentangWaktu.kustom) {
      final sekarang = DateTime.now();
      final rentang = await showDateRangePicker(
        context: context,
        firstDate: DateTime(sekarang.year - 2),
        lastDate: sekarang,
        initialDateRange: filter.kustom,
        helpText: "Pilih rentang tanggal",
      );
      if (rentang == null) return;
      onChanged(filter.denganWaktu(RentangWaktu.kustom, kustom: rentang));
    } else {
      onChanged(filter.denganWaktu(pilihan));
    }
  }

  Future<void> _pilihCabang(BuildContext context) async {
    // Nilai -1 = "Semua cabang" (null tidak bisa dibedakan dari sheet ditutup).
    final pilihan = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Cabang",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text("Semua cabang"),
              trailing: filter.cabangId == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(ctx, -1),
            ),
            ...daftarCabang.map((c) {
              final id = (c["id"] as num).toInt();
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(c["nama"].toString()),
                trailing: filter.cabangId == id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, id),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (pilihan == null) return;
    if (pilihan == -1) {
      onChanged(filter.denganCabang(null, null));
      return;
    }
    final cabang = daftarCabang.firstWhere(
      (c) => (c["id"] as num).toInt() == pilihan,
      orElse: () => null,
    );
    onChanged(filter.denganCabang(pilihan, cabang?["nama"]?.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final berubah = !filter.sama(awal);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text(filter.labelWaktu),
            onPressed: () => _pilihWaktu(context),
          ),
          ActionChip(
            avatar: const Icon(Icons.store, size: 16),
            label: Text(filter.labelCabang),
            onPressed: () => _pilihCabang(context),
          ),
          if (berubah)
            TextButton(
              onPressed: () => onChanged(awal),
              child: const Text("Reset"),
            ),
        ],
      ),
    );
  }
}
