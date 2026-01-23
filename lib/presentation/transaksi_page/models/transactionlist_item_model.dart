import 'package:equatable/equatable.dart';

/// This class is used in the [transactionlist_item_widget] screen.
// ignore_for_file: must_be_immutable
class TransactionModel extends Equatable {
  TransactionModel({
    this.id,
    this.pesananId,
    this.paymentId,
    this.status,
    this.waktuPembayaran,
    this.gunung,
    this.jalur,
    this.userId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      pesananId: json['id_pesanan'] is String
          ? int.parse(json['id_pesanan'])
          : json['id_pesanan'],
      paymentId: json['payment_id'] is String
          ? int.parse(json['payment_id'].toString())
          : json['payment_id'],
      status: json['status'],
      waktuPembayaran: json['waktu_pembayaran'],
      gunung: json['gunung'],
      jalur: json['jalur'],
      userId: json['pemesan'].toString(),
    );
  }

  final int? id;
  final int? pesananId;
  final int? paymentId;
  final String? status;
  final String? waktuPembayaran;
  final String? gunung;
  final String? jalur;
  final String? userId;

  TransactionModel copyWith({
    int? id,
    int? pesananId,
    int? paymentId,
    String? status,
    String? waktuPembayaran,
    String? gunung,
    String? jalur,
    String? userId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      pesananId: pesananId ?? this.pesananId,
      paymentId: paymentId ?? this.paymentId,
      status: status ?? this.status,
      waktuPembayaran: waktuPembayaran ?? this.waktuPembayaran,
      gunung: gunung ?? this.gunung,
      jalur: jalur ?? this.jalur,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pesananId,
        paymentId,
        status,
        waktuPembayaran,
        gunung,
        jalur,
        userId,
      ];
}
