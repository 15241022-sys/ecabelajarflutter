import 'package:flutter/material.dart';
import '../services/notifikasi_service.dart';

// Tombol lonceng di AppBar: meminta izin notifikasi dan mendaftarkan
// perangkat ini. Dibutuhkan karena browser (terutama Safari) hanya mau
// menampilkan dialog izin setelah pengguna menekan sesuatu.
class TombolNotifikasi extends StatelessWidget {
  const TombolNotifikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_active_outlined),
      tooltip: "Aktifkan notifikasi",
      onPressed: () async {
        final hasil = await NotifikasiService.instance.daftarkan(minta: true);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanHasil(hasil))),
        );
      },
    );
  }
}
