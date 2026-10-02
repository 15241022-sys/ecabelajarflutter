import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/kategori_service.dart';
import '../services/produk_service.dart';
import '../widgets/produk_card.dart';
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

  late Future<List<dynamic>> _kategoriFuture;
  late Future<List<dynamic>> _produkFuture;
  String? _kategoriAktif; // null = semua
  String _cari = "";

  @override
  void initState() {
    super.initState();
    _kategoriFuture = _kategoriService.getKategori();
    _muatProduk();
  }

  void _muatProduk() {
    _produkFuture = _produkService.getProduk(kategoriId: _kategoriAktif);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coffee Shop"),
        actions: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  return Center(child: Text("Gagal memuat menu: ${snapshot.error}"));
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
    );
  }
}
