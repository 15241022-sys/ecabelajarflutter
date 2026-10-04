import 'package:flutter/material.dart';

const metodeCash = "cash";
const metodeQris = "qris";
const bayarBelum = "belum_bayar";
const bayarLunas = "lunas";

const _hari = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
const _bulan = [
  "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
  "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
];

String dua(int n) => n.toString().padLeft(2, "0");

// Parse string waktu dari Supabase lalu ubah ke zona waktu perangkat.
DateTime? parseWaktu(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

// Contoh: "Sen, 5 Okt 2026 • 14:30"
String formatJadwal(dynamic v) {
  final d = parseWaktu(v);
  if (d == null) return "-";
  return "${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}"
      " • ${dua(d.hour)}:${dua(d.minute)}";
}

// Contoh: "Sen, 5 Okt 2026" (untuk header pengelompokan)
String formatHariTanggal(DateTime d) =>
    "${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}";

String labelMetode(dynamic m) =>
    m == metodeQris ? "QRIS" : "Cash di outlet (kasir)";

String labelBayar(dynamic s) => s == bayarLunas ? "Lunas" : "Belum dibayar";

Color warnaBayar(dynamic s) => s == bayarLunas ? Colors.green : Colors.deepOrange;
