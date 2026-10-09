import 'package:flutter/material.dart';
import '../../services/cabang_service.dart';
import '../../services/kategori_service.dart';

class ListKategoriScreen extends StatefulWidget {
  const ListKategoriScreen({super.key});

  @override
  State<ListKategoriScreen> createState() => _ListKategoriScreenState();
}

class _ListKategoriScreenState extends State<ListKategoriScreen> {
  final _service = KategoriService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getKategori(cabangId: CabangState.instance.id);
  }

  void _muatUlang() => setState(
      () => _future = _service.getKategori(cabangId: CabangState.instance.id));

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  // Dialog untuk tambah (kategori == null) atau ubah
  Future<void> _formDialog({Map<String, dynamic>? kategori}) async {
    final controller =
        TextEditingController(text: kategori?["nama_kategori"] ?? "");
    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(kategori == null ? "Tambah kategori" : "Ubah kategori"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nama kategori"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Simpan")),
        ],
      ),
    );

    final nama = controller.text.trim();
    if (simpan != true || nama.isEmpty) return;

    final cabangId = CabangState.instance.id;
    if (cabangId == null) {
      _pesan("Pilih cabang terlebih dahulu di dashboard");
      return;
    }

    final ok = kategori == null
        ? await _service.tambahKategori(nama, cabangId: cabangId)
        : await _service.ubahKategori(kategori["id"].toString(), nama);
    if (!mounted) return;
    _pesan(ok ? "Berhasil disimpan" : "Gagal menyimpan");
    if (ok) _muatUlang();
  }

  Future<void> _hapus(Map<String, dynamic> kategori) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus kategori?"),
        content: Text("Kategori \"${kategori["nama_kategori"]}\" akan dihapus."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus")),
        ],
      ),
    );
    if (yakin != true) return;

    final ok = await _service.hapusKategori(kategori["id"].toString());
    if (!mounted) return;
    _pesan(ok ? "Kategori dihapus" : "Gagal: kategori masih dipakai produk");
    if (ok) _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kategori • ${CabangState.instance.nama ?? "-"}")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _formDialog(),
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
          if (data.isEmpty) return const Center(child: Text("Belum ada kategori"));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final k = data[i] as Map<String, dynamic>;
              return ListTile(
                title: Text(k["nama_kategori"] ?? "-"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _formDialog(kategori: k)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _hapus(k)),
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
