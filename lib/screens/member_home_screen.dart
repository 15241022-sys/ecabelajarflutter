import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cabang_service.dart';
import '../services/cart_service.dart';
import '../services/kategori_service.dart';
import '../services/produk_service.dart';
import '../widgets/pilih_cabang.dart';
import '../widgets/produk_card.dart';
import '../widgets/tombol_notifikasi.dart';
import 'detail_produk_screen.dart';
import 'keranjang_screen.dart';
import 'login_screen.dart';
import 'riwayat_pesanan_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  final _produkService = ProdukService();
  final _kategoriService = KategoriService();
  final _cart = CartService.instance;
  final _cabang = CabangState.instance;

  Future<List<dynamic>> _kategoriFuture = Future.value(<dynamic>[]);
  Future<List<dynamic>> _produkFuture = Future.value(<dynamic>[]);
  String? _kategoriAktif; // null = semua
  String _cari = "";

  @override
  void initState() {
    super.initState();
    _muatSemua();
    // Belum memilih outlet: minta pilih begitu layar tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_cabang.terpilih) _pilihOutlet();
    });
  }

  // Menu dan kategori mengikuti outlet yang dipilih.
  void _muatSemua() {
    final id = _cabang.id;
    if (id == null) {
      _kategoriFuture = Future.value(<dynamic>[]);
      _produkFuture = Future.value(<dynamic>[]);
      return;
    }
    _kategoriFuture = _kategoriService.getKategori(cabangId: id);
    _muatProduk();
  }

  void _muatProduk() {
    final id = _cabang.id;
    _produkFuture = id == null
        ? Future.value(<dynamic>[])
        : _produkService.getProduk(kategoriId: _kategoriAktif, cabangId: id);
  }

  Future<void> _pilihOutlet() async {
    final c = await pilihCabangSheet(
      context,
      terpilihId: _cabang.id,
      judul: "Ambil pesanan di outlet mana?",
    );
    if (c == null || !mounted) return;

    final idBaru = (c["id"] as num).toInt();
    if (idBaru == _cabang.id) return;

    // Menu tiap outlet berbeda, jadi keranjang lama tidak bisa dipakai.
    if (!_cart.isEmpty) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Ganti outlet?"),
          content: const Text(
              "Menu dan stok tiap outlet berbeda, jadi keranjang akan dikosongkan."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Ganti")),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
      _cart.kosongkan();
    }

    await _cabang.pilih(idBaru, c["nama"].toString());
    if (!mounted) return;
    setState(() {
      _kategoriAktif = null;
      _muatSemua();
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();
    _cart.kosongkan();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _tambahKeKeranjang(Map<String, dynamic> item) {
    _cart.tambah(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item["nama_produk"]} ditambahkan"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _barOutlet() {
    return Material(
      color: Colors.brown.shade50,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.store),
        title: Text(
          _cabang.terpilih
              ? "Ambil di outlet ${_cabang.nama}"
              : "Belum memilih outlet",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: TextButton(
          onPressed: _pilihOutlet,
          child: Text(_cabang.terpilih ? "Ubah" : "Pilih"),
        ),
      ),
    );
  }

  Widget _belumPilihOutlet() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 64, color: Colors.brown),
              const SizedBox(height: 12),
              const Text(
                "Pilih outlet pengambilan untuk melihat menu dan mulai memesan",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pilihOutlet,
                icon: const Icon(Icons.store),
                label: const Text("Pilih outlet"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coffee Shop"),
        actions: [
          const TombolNotifikasi(),
          ListenableBuilder(
            listenable: _cart,
            builder: (context, _) => IconButton(
              icon: Badge(
                isLabelVisible: _cart.totalItem > 0,
                label: Text("${_cart.totalItem}"),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeranjangScreen()),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: "Riwayat pesanan",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiwayatPesananScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          _barOutlet(),
          if (!_cabang.terpilih)
            _belumPilihOutlet()
          else ...[
            // Pencarian
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                onChanged: (v) => setState(() => _cari = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Cari menu",
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Filter kategori
            SizedBox(
              height: 56,
              child: FutureBuilder<List<dynamic>>(
                future: _kategoriFuture,
                builder: (context, snapshot) {
                  final kategori = snapshot.data ?? [];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text("Semua"),
                          selected: _kategoriAktif == null,
                          onSelected: (_) => setState(() {
                            _kategoriAktif = null;
                            _muatProduk();
                          }),
                        ),
                      ),
                      ...kategori.map((k) {
                        final id = k["id"].toString();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(k["nama_kategori"] ?? "-"),
                            selected: _kategoriAktif == id,
                            onSelected: (_) => setState(() {
                              _kategoriAktif = id;
                              _muatProduk();
                            }),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            // Grid produk
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _produkFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Gagal memuat menu: ${snapshot.error}"));
                  }
                  final produk = (snapshot.data ?? [])
                      .where((p) => (p["nama_produk"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(_cari))
                      .toList();
                  if (produk.isEmpty) {
                    return const Center(child: Text("Menu tidak ditemukan"));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: produk.length,
                    itemBuilder: (context, index) {
                      final item = produk[index] as Map<String, dynamic>;
                      return ProdukCard(
                        produk: item,
                        onTambah: () => _tambahKeKeranjang(item),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailProdukScreen(produk: item),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
