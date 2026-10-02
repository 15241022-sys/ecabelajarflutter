import 'package:flutter/material.dart';
import '../../services/kategori_service.dart';
import '../../services/produk_service.dart';

// Form tambah (produk == null) sekaligus ubah (produk terisi)
class FormProdukScreen extends StatefulWidget {
  final Map<String, dynamic>? produk;
  const FormProdukScreen({super.key, this.produk});

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  final _produkService = ProdukService();

  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _deskripsi;
  late final TextEditingController _gambar;
  late final TextEditingController _stok;

  List<dynamic> _kategori = [];
  String? _kategoriId;
  bool _loading = false;

  bool get _modeUbah => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _nama = TextEditingController(text: p?["nama_produk"] ?? "");
    _harga = TextEditingController(text: p?["harga"]?.toString() ?? "");
    _deskripsi = TextEditingController(text: p?["deskripsi"] ?? "");
    _gambar = TextEditingController(text: p?["gambar"] ?? "");
    _stok = TextEditingController(text: p?["stok"]?.toString() ?? "");
    _kategoriId = p?["kategori_id"]?.toString();
    _muatKategori();
  }

  Future<void> _muatKategori() async {
    final data = await KategoriService().getKategori();
    if (!mounted) return;
    setState(() => _kategori = data);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final harga = int.parse(_harga.text);
    final stok = int.parse(_stok.text);

    final ok = _modeUbah
        ? await _produkService.ubahProduk(
            id: widget.produk!["id"].toString(),
            kategoriId: _kategoriId!,
            namaProduk: _nama.text.trim(),
            harga: harga,
            deskripsi: _deskripsi.text.trim(),
            gambar: _gambar.text.trim(),
            stok: stok,
          )
        : await _produkService.tambahProduk(
            kategoriId: _kategoriId!,
            namaProduk: _nama.text.trim(),
            harga: harga,
            deskripsi: _deskripsi.text.trim(),
            gambar: _gambar.text.trim(),
            stok: stok,
          );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan produk")),
      );
    }
  }

  String? _wajibAngka(String? v) =>
      (v == null || int.tryParse(v) == null) ? "Isi dengan angka" : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modeUbah ? "Ubah produk" : "Tambah produk")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _kategori.any((k) => k["id"].toString() == _kategoriId)
                    ? _kategoriId
                    : null,
                decoration: const InputDecoration(labelText: "Kategori"),
                items: _kategori
                    .map((k) => DropdownMenuItem(
                          value: k["id"].toString(),
                          child: Text(k["nama_kategori"] ?? "-"),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _kategoriId = v),
                validator: (v) => v == null ? "Pilih kategori" : null,
              ),
              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(labelText: "Nama produk"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _harga,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga"),
                validator: _wajibAngka,
              ),
              TextFormField(
                controller: _stok,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok"),
                validator: _wajibAngka,
              ),
              TextFormField(
                controller: _deskripsi,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Deskripsi"),
              ),
              TextFormField(
                controller: _gambar,
                decoration: const InputDecoration(labelText: "URL gambar (opsional)"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _simpan,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
