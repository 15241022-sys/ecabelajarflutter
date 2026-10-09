import 'package:flutter/material.dart';
import 'pesanan_util.dart';

enum RentangWaktu { semua, hariIni, tujuhHari, tigaPuluhHari, bulanIni, kustom }

String labelRentang(RentangWaktu w) {
  switch (w) {
    case RentangWaktu.semua:
      return "Semua waktu";
    case RentangWaktu.hariIni:
      return "Hari ini";
    case RentangWaktu.tujuhHari:
      return "7 hari terakhir";
    case RentangWaktu.tigaPuluhHari:
      return "30 hari terakhir";
    case RentangWaktu.bulanIni:
      return "Bulan ini";
    case RentangWaktu.kustom:
      return "Pilih rentang tanggal...";
  }
}

// Filter riwayat pesanan: waktu pemesanan + cabang.
// cabangId == null berarti "Semua cabang".
class FilterPesanan {
  final RentangWaktu waktu;
  final DateTimeRange? kustom;
  final int? cabangId;
  final String? cabangNama;

  const FilterPesanan({
    this.waktu = RentangWaktu.semua,
    this.kustom,
    this.cabangId,
    this.cabangNama,
  });

  FilterPesanan denganWaktu(RentangWaktu w, {DateTimeRange? kustom}) =>
      FilterPesanan(
        waktu: w,
        kustom: w == RentangWaktu.kustom ? kustom : null,
        cabangId: cabangId,
        cabangNama: cabangNama,
      );

  FilterPesanan denganCabang(int? id, String? nama) => FilterPesanan(
        waktu: waktu,
        kustom: kustom,
        cabangId: id,
        cabangNama: nama,
      );

  // Batas awal (inklusif), dalam waktu lokal perangkat.
  DateTime? get mulai {
    final n = DateTime.now();
    final hari = DateTime(n.year, n.month, n.day);
    switch (waktu) {
      case RentangWaktu.semua:
        return null;
      case RentangWaktu.hariIni:
        return hari;
      case RentangWaktu.tujuhHari:
        return DateTime(hari.year, hari.month, hari.day - 6);
      case RentangWaktu.tigaPuluhHari:
        return DateTime(hari.year, hari.month, hari.day - 29);
      case RentangWaktu.bulanIni:
        return DateTime(n.year, n.month, 1);
      case RentangWaktu.kustom:
        final k = kustom;
        return k == null
            ? null
            : DateTime(k.start.year, k.start.month, k.start.day);
    }
  }

  // Batas akhir (eksklusif); null = tanpa batas akhir.
  DateTime? get akhir {
    if (waktu != RentangWaktu.kustom) return null;
    final k = kustom;
    if (k == null) return null;
    return DateTime(k.end.year, k.end.month, k.end.day + 1);
  }

  String get labelWaktu {
    if (waktu == RentangWaktu.kustom && kustom != null) {
      final a = kustom!.start;
      final b = kustom!.end;
      if (a.year == b.year && a.month == b.month && a.day == b.day) {
        return formatTglPendek(a);
      }
      return "${formatTglPendek(a)} – ${formatTglPendek(b)}";
    }
    return labelRentang(waktu);
  }

  String get labelCabang =>
      cabangId == null ? "Semua cabang" : (cabangNama ?? "Cabang $cabangId");

  bool sama(FilterPesanan o) =>
      waktu == o.waktu && kustom == o.kustom && cabangId == o.cabangId;
}
