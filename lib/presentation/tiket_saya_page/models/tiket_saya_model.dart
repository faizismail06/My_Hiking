import 'package:equatable/equatable.dart';

// ignore_for_file: must_be_immutable

/// Model for an order/ticket item
class TiketItemModel extends Equatable {
  final String? id;
  final String? tanggalNaik;
  final String? tanggalTurun;
  final String? gunung;
  final String? jalur;
  final String? status;
  final int? totalHarga;

  const TiketItemModel({
    this.id,
    this.tanggalNaik,
    this.tanggalTurun,
    this.gunung,
    this.jalur,
    this.status,
    this.totalHarga,
  });

  factory TiketItemModel.fromJson(Map<String, dynamic> json) {
    return TiketItemModel(
      id: json['id']?.toString(),
      tanggalNaik: json['tanggal_naik'],
      tanggalTurun: json['tanggal_turun'],
      gunung: json['gunung'],
      jalur: json['jalur'],
      status: json['status'],
      totalHarga: json['total_harga_tiket'] is int
          ? json['total_harga_tiket']
          : int.tryParse((json['total_harga_tiket'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props =>
      [id, tanggalNaik, tanggalTurun, gunung, jalur, status, totalHarga];
}

/// Model for a transaction item
class TransaksiItemModel extends Equatable {
  final int? id;
  final int? pesananId;
  final String? status;
  final String? waktuPembayaran;
  final String? gunung;
  final String? jalur;
  final String? paymentType;

  const TransaksiItemModel({
    this.id,
    this.pesananId,
    this.status,
    this.waktuPembayaran,
    this.gunung,
    this.jalur,
    this.paymentType,
  });

  factory TransaksiItemModel.fromJson(Map<String, dynamic> json) {
    return TransaksiItemModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      pesananId: json['id_pesanan'] is String
          ? int.parse(json['id_pesanan'])
          : json['id_pesanan'],
      status: json['status'],
      waktuPembayaran: json['waktu_pembayaran'],
      gunung: json['gunung'],
      jalur: json['jalur'],
      paymentType: json['payment_type'],
    );
  }

  @override
  List<Object?> get props =>
      [id, pesananId, status, waktuPembayaran, gunung, jalur, paymentType];
}

/// Aggregate model holding both lists
class TiketSayaModel extends Equatable {
  final List<TiketItemModel> activeTicketsList;
  final List<TiketItemModel> completedHikesList;

  const TiketSayaModel({
    this.activeTicketsList = const [],
    this.completedHikesList = const [],
  });

  TiketSayaModel copyWith({
    List<TiketItemModel>? activeTicketsList,
    List<TiketItemModel>? completedHikesList,
  }) {
    return TiketSayaModel(
      activeTicketsList: activeTicketsList ?? this.activeTicketsList,
      completedHikesList: completedHikesList ?? this.completedHikesList,
    );
  }

  @override
  List<Object?> get props => [activeTicketsList, completedHikesList];
}
