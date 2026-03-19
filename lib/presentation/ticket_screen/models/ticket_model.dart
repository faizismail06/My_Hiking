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
  final String transactionStatus;
  final bool canPrintTicket;
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
    required this.transactionStatus,
    required this.canPrintTicket,
    required this.anggota,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // API returns: booker, mountain, trail, members
    return TicketModel(
      id: json['id'] ?? 0,
      pemesanName: json['booker']?['name'] ??
          'Unknown', // API uses 'booker' not 'pemesan'
      gunungName: json['mountain']?['nama'] ?? 'Unknown',
      jalurName: json['trail']?['nama'] ?? 'Unknown',
      tanggalNaik: json['tanggal_naik'] ?? '',
      tanggalTurun: json['tanggal_turun'] ?? '',
      totalHargaTiket: json['total_harga_tiket'] ?? 0,
      status: json['status'] ?? 'Unknown',
      transactionStatus: json['transaction']?['status_pesanan'] ?? 'Incomplete',
      canPrintTicket:
          (json['transaction']?['status_pesanan'] ?? 'Incomplete') ==
              'Complete',
      anggota: (json['members'] as List?)
              ?.map(
                  (member) => Anggota.fromJson(member as Map<String, dynamic>))
              .toList() ??
          [], // API uses 'members' not 'anggota'
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
    String? transactionStatus,
    bool? canPrintTicket,
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
      transactionStatus: transactionStatus ?? this.transactionStatus,
      canPrintTicket: canPrintTicket ?? this.canPrintTicket,
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
        transactionStatus,
        canPrintTicket,
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
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props => [id, name];
}
