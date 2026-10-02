import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class DetailProdukScreen extends StatefulWidget {
  final Map<String, dynamic> produk;
  const DetailProdukScreen({super.key, required this.produk});

  @override
  State<DetailProdukScreen> createState() => _DetailProdukScreenState();
}

class _DetailProdukScreenState extends State<DetailProdukScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final stok = (p["stok"] ?? 0) as int;
    final gambar = (p["gambar"] ?? "") as String;

    return Scaffold(
      appBar: AppBar(title: Text(p["nama_produk"] ?? "Detail produk")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: gambar.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(gambar, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.coffee, size: 64)),
                    )
                  : const Icon(Icons.coffee, size: 64),
            ),
            const SizedBox(height: 16),
            Text(p["nama_produk"] ?? "-",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("Rp${p["harga"]}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text(p["deskripsi"] ?? ""),
            const SizedBox(height: 8),
            Text("Stok: $stok", style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                ),
                Text("$_qty", style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _qty < stok ? () => setState(() => _qty++) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text("Tambah ke keranjang"),
                    onPressed: stok == 0
                        ? null
                        : () {
                            CartService.instance.tambah(p, qty: _qty);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Ditambahkan ke keranjang")),
                            );
                            Navigator.pop(context);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
