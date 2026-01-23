import 'package:equatable/equatable.dart';

class MenungguVerifikasiModel extends Equatable {
  final int? idPesanan;
  final String? tanggalPesanan;
  final String? namaPemesan;
  final int? totalAnggota;
  final int? totalHarga;

  const MenungguVerifikasiModel({
    this.idPesanan,
    this.tanggalPesanan,
    this.namaPemesan,
    this.totalAnggota,
    this.totalHarga,
  });

  MenungguVerifikasiModel copyWith({
    int? idPesanan,
    String? tanggalPesanan,
    String? namaPemesan,
    int? totalAnggota,
    int? totalHarga,
  }) {
    return MenungguVerifikasiModel(
      idPesanan: idPesanan ?? this.idPesanan,
      tanggalPesanan: tanggalPesanan ?? this.tanggalPesanan,
      namaPemesan: namaPemesan ?? this.namaPemesan,
      totalAnggota: totalAnggota ?? this.totalAnggota,
      totalHarga: totalHarga ?? this.totalHarga,
    );
  }

  factory MenungguVerifikasiModel.fromJson(Map<String, dynamic> json) {
    return MenungguVerifikasiModel(
      idPesanan: json['id_pesanan'] as int?,
      tanggalPesanan: json['tanggal_pesanan'] as String?,
      namaPemesan: json['nama_pemesan'] as String?,
      totalAnggota: json['total_anggota'] as int?,
      totalHarga: json['total_harga'] as int?,
    );
  }

  @override
  List<Object?> get props =>
      [idPesanan, tanggalPesanan, namaPemesan, totalAnggota, totalHarga];
}
