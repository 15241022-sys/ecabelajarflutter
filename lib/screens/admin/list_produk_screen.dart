import 'package:flutter/material.dart';
import '../../services/cabang_service.dart';
import '../../services/produk_service.dart';
import 'form_produk_screen.dart';

class ListProdukScreen extends StatefulWidget {
  const ListProdukScreen({super.key});

  @override
  State<ListProdukScreen> createState() => _ListProdukScreenState();
}

class _ListProdukScreenState extends State<ListProdukScreen> {
  final _service = ProdukService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getProduk(cabangId: CabangState.instance.id);
  }

  void _muatUlang() => setState(
      () => _future = _service.getProduk(cabangId: CabangState.instance.id));

  Future<void> _bukaForm({Map<String, dynamic>? produk}) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormProdukScreen(produk: produk)),
    );
    if (berubah == true) _muatUlang();
  }

  Future<void> _hapus(Map<String, dynamic> produk) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus produk?"),
        content: Text("\"${produk["nama_produk"]}\" akan dihapus."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus")),
        ],
      ),
    );
    if (yakin != true) return;

    final ok = await _service.hapusProduk(produk["id"].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? "Produk dihapus" : "Gagal: produk sudah pernah dipesan"),
    ));
    if (ok) _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Produk • ${CabangState.instance.nama ?? "-"}")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat: ${snapshot.error}"));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) return const Center(child: Text("Belum ada produk"));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = data[i] as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.coffee),
                title: Text(p["nama_produk"] ?? "-"),
                subtitle: Text("Rp${p["harga"]}  •  stok ${p["stok"]}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _bukaForm(produk: p)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _hapus(p)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
