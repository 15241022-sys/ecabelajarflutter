import 'package:flutter/material.dart';

// Format angka jadi Rupiah, contoh: 25000 -> Rp25.000
String formatRupiah(num angka) {
  final s = angka.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return "Rp$buf";
}

// Kartu produk untuk tampilan grid menu member
class ProdukCard extends StatelessWidget {
  final Map<String, dynamic> produk;
  final VoidCallback onTap;
  final VoidCallback onTambah;

  const ProdukCard({
    super.key,
    required this.produk,
    required this.onTap,
    required this.onTambah,
  });

  @override
  Widget build(BuildContext context) {
    final gambar = (produk["gambar"] ?? "").toString();
    final stok = (produk["stok"] ?? 0) as int;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.brown.shade50,
                child: gambar.isNotEmpty
                    ? Image.network(
                        gambar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.coffee, size: 48, color: Colors.brown),
                      )
                    : const Icon(Icons.coffee, size: 48, color: Colors.brown),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produk["nama_produk"] ?? "-",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stok == 0 ? "Habis" : formatRupiah(produk["harga"] ?? 0),
                          style: TextStyle(
                            color: stok == 0 ? Colors.red : Colors.brown.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: const Color(0xFF6F4E37),
                    onPressed: stok == 0 ? null : onTambah,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
