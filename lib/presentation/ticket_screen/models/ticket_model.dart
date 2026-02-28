import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [ticket_screen],
/// and is typically used to hold data that is passed between different parts of the application.

/// This class defines the variables used in the [ticket_screen],
/// and is typically used to hold data that is passed between different parts of the application.

class TicketModel extends Equatable {
  final int id;
  final String pemesanName;
  final String gunungName;
  final String jalurName;
  final String tanggalNaik;
  final String tanggalTurun;
  final int totalHargaTiket;
  final String status;
  final List<Anggota> anggota;

  const TicketModel({
    required this.id,
    required this.pemesanName,
    required this.gunungName,
    required this.jalurName,
    required this.tanggalNaik,
    required this.tanggalTurun,
    required this.totalHargaTiket,
    required this.status,
    required this.anggota,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
  // Periksa apakah 'pesanan' dan sub-elemen lainnya tidak null  
  return TicketModel(
    
    id: json['id'] ?? 0, // Gunakan nilai default jika tidak ada 'id'
    pemesanName: json['pemesan']?['name'] ?? 'Unknown', // Gunakan 'Unknown' jika 'pemesan' atau 'name' tidak ditemukan
    gunungName: json['mountain']?['nama'] ?? 'Unknown', // Gunakan 'Unknown' jika 'mountain' atau 'nama' tidak ditemukan
    jalurName: json['trail']?['nama'] ?? 'Unknown', // Gunakan 'Unknown' jika 'trail' atau 'nama' tidak ditemukan
    tanggalNaik: json['tanggal_naik'] ?? '', // Gunakan string kosong jika tanggal_naik tidak ditemukan
    tanggalTurun: json['tanggal_turun'] ?? '', // Gunakan string kosong jika tanggal_turun tidak ditemukan
    totalHargaTiket: json['total_harga_tiket'] ?? 0, // Gunakan 0 jika total_harga_tiket tidak ditemukan
    status: json['status'] ?? 'Unknown', // Gunakan 'Unknown' jika status tidak ditemukan
    anggota: (json['anggota'] as List?)?.map((anggota) => Anggota.fromJson(anggota)).toList() ?? [], // Pastikan anggota tidak null
  );
}


  // Method to copy this object with updated values
  TicketModel copyWith({
    int? id,
    String? pemesanName,
    String? gunungName,
    String? jalurName,
    String? tanggalNaik,
    String? tanggalTurun,
    int? totalHargaTiket,
    String? status,
    List<Anggota>? anggota,
  }) {
    return TicketModel(
      id: id ?? this.id,
      pemesanName: pemesanName ?? this.pemesanName,
      gunungName: gunungName ?? this.gunungName,
      jalurName: jalurName ?? this.jalurName,
      tanggalNaik: tanggalNaik ?? this.tanggalNaik,
      tanggalTurun: tanggalTurun ?? this.tanggalTurun,
      totalHargaTiket: totalHargaTiket ?? this.totalHargaTiket,
      status: status ?? this.status,
      anggota: anggota ?? this.anggota,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pemesanName,
        gunungName,
        jalurName,
        tanggalNaik,
        tanggalTurun,
        totalHargaTiket,
        status,
        anggota,
      ];
}

// Model to represent Anggota (member) in the Ticket
class Anggota extends Equatable {
  final int id;
  final String name;

  const Anggota({
    required this.id,
    required this.name,
  });

  // Factory method to create an Anggota from JSON
  factory Anggota.fromJson(Map<String, dynamic> json) {
    return Anggota(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  List<Object?> get props => [id, name];
}
