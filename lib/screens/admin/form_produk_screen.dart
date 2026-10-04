import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/kategori_service.dart';
import '../../services/produk_service.dart';
import '../../services/storage_service.dart';

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
  final _storageService = StorageService();
  final _picker = ImagePicker();

  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _deskripsi;
  late final TextEditingController _stok;

  // Gambar: URL lama (mode ubah) atau bytes gambar baru dari galeri.
  String _gambarUrl = "";
  Uint8List? _gambarBaru;
  String _namaFileBaru = "";

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
    _gambarUrl = (p?["gambar"] ?? "").toString();
    _stok = TextEditingController(text: p?["stok"]?.toString() ?? "");
    _kategoriId = p?["kategori_id"]?.toString();
    _muatKategori();
  }

  Future<void> _muatKategori() async {
    final data = await KategoriService().getKategori();
    if (!mounted) return;
    setState(() => _kategori = data);
  }

  // Buka galeri / penyimpanan perangkat untuk memilih foto produk.
  Future<void> _pilihGambar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280, // perkecil supaya upload cepat & hemat storage
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _gambarBaru = bytes;
        _namaFileBaru = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak bisa membuka galeri: $e")),
      );
    }
  }

  void _hapusGambar() => setState(() {
        _gambarBaru = null;
        _namaFileBaru = "";
        _gambarUrl = "";
      });

  Widget _previewGambar() {
    Widget isi;
    if (_gambarBaru != null) {
      isi = Image.memory(_gambarBaru!, fit: BoxFit.cover);
    } else if (_gambarUrl.isNotEmpty) {
      isi = Image.network(
        _gambarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 48, color: Colors.brown),
      );
    } else {
      isi = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.brown),
          SizedBox(height: 8),
          Text("Ketuk untuk pilih foto"),
        ],
      );
    }
    return InkWell(
      onTap: _loading ? null : _pilihGambar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.brown.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade100),
        ),
        child: Center(child: isi),
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final harga = int.parse(_harga.text);
    final stok = int.parse(_stok.text);

    // Jika ada gambar baru dari galeri, upload dulu lalu pakai URL-nya.
    var gambar = _gambarUrl;
    if (_gambarBaru != null) {
      try {
        gambar = await _storageService.uploadGambarProduk(
          bytes: _gambarBaru!,
          namaFile: _namaFileBaru,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
        return;
      }
    }

    final ok = _modeUbah
        ? await _produkService.ubahProduk(
            id: widget.produk!["id"].toString(),
            kategoriId: _kategoriId!,
            namaProduk: _nama.text.trim(),
            harga: harga,
            deskripsi: _deskripsi.text.trim(),
            gambar: gambar,
            stok: stok,
          )
        : await _produkService.tambahProduk(
            kategoriId: _kategoriId!,
            namaProduk: _nama.text.trim(),
            harga: harga,
            deskripsi: _deskripsi.text.trim(),
            gambar: gambar,
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Foto produk (opsional)",
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              _previewGambar(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _loading ? null : _pilihGambar,
                    icon: const Icon(Icons.photo_library),
                    label: Text((_gambarBaru != null || _gambarUrl.isNotEmpty)
                        ? "Ganti foto"
                        : "Pilih dari galeri"),
                  ),
                  if (_gambarBaru != null || _gambarUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: _loading ? null : _hapusGambar,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text("Hapus",
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
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
