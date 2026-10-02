import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/pesanan_service.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final _cart = CartService.instance;
  bool _loading = false;

  Future<void> _checkout() async {
    setState(() => _loading = true);

    final userId = await AuthService().getUserId();
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final items = _cart.items
        .map((i) => {
              "produk_id": i.produk["id"],
              "qty": i.qty,
              "subtotal": i.subtotal,
            })
        .toList();

    final ok = await PesananService().buatPesanan(
      userId: userId,
      totalHarga: _cart.totalHarga,
      items: items,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      _cart.kosongkan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesanan berhasil dibuat")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout gagal, coba lagi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: ListenableBuilder(
        listenable: _cart,
        builder: (context, _) {
          if (_cart.isEmpty) {
            return const Center(child: Text("Keranjang masih kosong"));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _cart.items.length,
                  itemBuilder: (context, index) {
                    final item = _cart.items[index];
                    final id = item.produk["id"] as int;
                    return ListTile(
                      title: Text(item.produk["nama_produk"] ?? "-"),
                      subtitle: Text("Rp${item.harga} x ${item.qty} = Rp${item.subtotal}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _cart.ubahQty(id, item.qty - 1),
                          ),
                          Text("${item.qty}"),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _cart.ubahQty(id, item.qty + 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Total: Rp${_cart.totalHarga}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      onPressed: _loading ? null : _checkout,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
