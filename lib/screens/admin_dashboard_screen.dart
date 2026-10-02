import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin/list_kategori_screen.dart';
import 'admin/list_pesanan_screen.dart';
import 'admin/list_produk_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget _menuCard(
    BuildContext context,
    IconData icon,
    String judul,
    Widget tujuan,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(judul),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => tujuan),
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
          _menuCard(context, Icons.local_cafe, "Kelola produk", const ListProdukScreen()),
          _menuCard(context, Icons.category, "Kelola kategori", const ListKategoriScreen()),
          _menuCard(context, Icons.receipt_long, "Pesanan masuk", const ListPesananScreen()),
        ],
      ),
    );
  }
}
