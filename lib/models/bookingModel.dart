import 'dart:convert';

Booking bookingFromJson(String str) => Booking.fromJson(json.decode(str));

String bookingToJson(Booking data) => json.encode(data.toJson());

class Booking {
  bool success;
  String message;
  ModelBooking data;

  Booking({
    required this.success,
    required this.message,
    required this.data,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      success: json["success"],
      message: json["message"],
      data:
          ModelBooking.fromJson(json["order"]), // Directly passing 'order'
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "order": data.toJson(),
      };
}

class ModelBooking {
  final int id;
  final int idGunung;
  final int jalurId;
  final int userId;
  final DateTime tanggalNaik;
  final DateTime tanggalTurun;
  final int totalHargaTiket;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<Anggota>? anggotaIds;

  ModelBooking({
    required this.id,
    required this.idGunung,
    required this.jalurId,
    required this.userId,
    required this.tanggalNaik,
    required this.tanggalTurun,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.totalHargaTiket,
    this.anggotaIds,
  });

  factory ModelBooking.fromJson(Map<String, dynamic> json) {
    return ModelBooking(
      id: json['id'],
      idGunung: json['id_gunung'],
      jalurId: json['id_jalur'],
      userId: json['id_user'],
      tanggalNaik: DateTime.parse(json['tanggal_naik']),
      tanggalTurun: DateTime.parse(json['tanggal_turun']),
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      totalHargaTiket: json['total_harga_tiket'],
      anggotaIds: json['members'] != null
          ? (json['members'] as List)
              .map((item) => Anggota.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_gunung': idGunung,
      'id_jalur': jalurId,
      'id_user': userId,
      'tanggal_naik': tanggalNaik.toIso8601String(),
      'tanggal_turun': tanggalTurun.toIso8601String(),
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'total_harga_tiket': totalHargaTiket,
      'members': anggotaIds != null
          ? anggotaIds!.map((anggota) => anggota.toJson()).toList()
          : [],
    };
  }
}

class Anggota {
  final int id;
  final String name;
  final String email;

  Anggota({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Anggota.fromJson(Map<String, dynamic> json) {
    return Anggota(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class TransactionResponseModel {
  final String message;
  final TransactionModel transaction;

  TransactionResponseModel({
    required this.message,
    required this.transaction,
  });

  factory TransactionResponseModel.fromJson(Map<String, dynamic> json) {
    return TransactionResponseModel(
      message: json['message'],
      transaction: TransactionModel.fromJson(json['transaction']),
    );
  }
}

class TransactionModel {
  final int id;
  final int idPesanan;
  final int totalBayar;
  final String statusPesanan;
  final String? waktuPembayaran;
  final String? bukti;
  final String? paymentType; // Midtrans payment type
  final String? paymentMethodName; // Human-readable payment method name
  String? gunung;
  String? jalur;
  String? userId;

  TransactionModel({
    required this.id,
    required this.idPesanan,
    required this.totalBayar,
    required this.statusPesanan,
    this.waktuPembayaran,
    this.bukti,
    this.paymentType,
    this.paymentMethodName,
    this.gunung,
    this.jalur,
    this.userId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      idPesanan: json['id_pesanan'],
      totalBayar: json['total_bayar'],
      statusPesanan: json['status_pesanan'],
      waktuPembayaran: json['waktu_pembayaran'],
      bukti: json['bukti'],
      paymentType: json['payment_type'],
      paymentMethodName: json['payment_method_name'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_pesanan': idPesanan,
      'total_bayar': totalBayar,
      'status_pesanan': statusPesanan,
      'waktu_pembayaran': waktuPembayaran,
      'bukti': bukti,
      'payment_type': paymentType,
    };
  }
}

class BookingWithTransaction {
  final ModelBooking booking;
  final TransactionModel transaksi;

  BookingWithTransaction({
    required this.booking,
    required this.transaksi,
  });

  // Factory method untuk membuat objek dari JSON
  factory BookingWithTransaction.fromJson(Map<String, dynamic> json) {
    return BookingWithTransaction(
      booking: ModelBooking.fromJson(json['booking']),
      transaksi: TransactionModel.fromJson(json['transaksi']),
    );
  }

  // Method untuk mengubah objek ke JSON
  Map<String, dynamic> toJson() {
    return {
      'booking': booking.toJson(),
      'transaksi': transaksi.toJson(),
    };
  }
}
