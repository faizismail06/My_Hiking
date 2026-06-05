import 'package:equatable/equatable.dart';

class PendingVerificationModel extends Equatable {
  final int? idPesanan;
  final String? tanggalPesanan;
  final String? namaPemesan;
  final int? totalAnggota;
  final int? totalHarga;

  const PendingVerificationModel({
    this.idPesanan,
    this.tanggalPesanan,
    this.namaPemesan,
    this.totalAnggota,
    this.totalHarga,
  });

  PendingVerificationModel copyWith({
    int? idPesanan,
    String? tanggalPesanan,
    String? namaPemesan,
    int? totalAnggota,
    int? totalHarga,
  }) {
    return PendingVerificationModel(
      idPesanan: idPesanan ?? this.idPesanan,
      tanggalPesanan: tanggalPesanan ?? this.tanggalPesanan,
      namaPemesan: namaPemesan ?? this.namaPemesan,
      totalAnggota: totalAnggota ?? this.totalAnggota,
      totalHarga: totalHarga ?? this.totalHarga,
    );
  }

  factory PendingVerificationModel.fromJson(Map<String, dynamic> json) {
    return PendingVerificationModel(
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
