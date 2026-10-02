import 'package:flutter/foundation.dart';

class CartItem {
  final Map<String, dynamic> produk;
  int qty;
  CartItem(this.produk, this.qty);

  int get harga => (produk["harga"] as num).toInt();
  int get subtotal => harga * qty;
}

// Keranjang disimpan di memori (state lokal), tidak perlu tabel di database.
// Singleton: semua halaman memakai satu keranjang yang sama.
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItem => _items.fold(0, (sum, i) => sum + i.qty);
  int get totalHarga => _items.fold(0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => _items.isEmpty;

  void tambah(Map<String, dynamic> produk, {int qty = 1}) {
    final index = _items.indexWhere((i) => i.produk["id"] == produk["id"]);
    if (index >= 0) {
      _items[index].qty += qty;
    } else {
      _items.add(CartItem(produk, qty));
    }
    notifyListeners();
  }

  void ubahQty(int produkId, int qtyBaru) {
    final index = _items.indexWhere((i) => i.produk["id"] == produkId);
    if (index < 0) return;
    if (qtyBaru <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].qty = qtyBaru;
    }
    notifyListeners();
  }

  void kosongkan() {
    _items.clear();
    notifyListeners();
  }
}
