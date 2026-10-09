import 'package:flutter/material.dart';
import '../services/cabang_service.dart';

// Menampilkan daftar cabang dalam bottom sheet.
// Mengembalikan data cabang yang dipilih (Map: id, nama, alamat), atau null.
Future<Map<String, dynamic>?> pilihCabangSheet(
  BuildContext context, {
  int? terpilihId,
  String judul = "Pilih outlet",
}) async {
  List<dynamic> daftar;
  try {
    daftar = await CabangService().getCabang();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    }
    return null;
  }
  if (!context.mounted) return null;

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(judul,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          if (daftar.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("Belum ada cabang tersedia"),
            ),
          ...daftar.map((c) {
            final data = c as Map<String, dynamic>;
            final dipilih = (data["id"] as num).toInt() == terpilihId;
            final alamat = (data["alamat"] ?? "").toString();
            return ListTile(
              leading: const Icon(Icons.store),
              title: Text(data["nama"].toString()),
              subtitle: alamat.isEmpty ? null : Text(alamat),
              trailing: dipilih ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () => Navigator.pop(ctx, data),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
