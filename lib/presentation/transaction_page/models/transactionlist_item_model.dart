import 'package:equatable/equatable.dart';

/// This class is used in the [transactionlist_item_widget] screen.
// ignore_for_file: must_be_immutable
class TransactionItemModel extends Equatable {
  TransactionItemModel({
    this.id,
    this.pesananId,
    this.status,
    this.waktuPembayaran,
    this.gunung,
    this.jalur,
    this.userId,
    this.paymentType,
    this.paymentMethodName,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      pesananId: json['id_pesanan'] is String
          ? int.parse(json['id_pesanan'])
          : json['id_pesanan'],
      status: json['status'],
      waktuPembayaran: json['waktu_pembayaran'],
      gunung: json['gunung'],
      jalur: json['jalur'],
      userId: json['pemesan'].toString(),
      paymentType: json['payment_type'],
      paymentMethodName: json['payment_method_name'],
    );
  }

  final int? id;
  final int? pesananId;
  final String? status;
  final String? waktuPembayaran;
  final String? gunung;
  final String? jalur;
  final String? userId;
  final String? paymentType;
  final String? paymentMethodName;

  TransactionItemModel copyWith({
    int? id,
    int? pesananId,
    String? status,
    String? waktuPembayaran,
    String? gunung,
    String? jalur,
    String? userId,
    String? paymentType,
    String? paymentMethodName,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      pesananId: pesananId ?? this.pesananId,
      status: status ?? this.status,
      waktuPembayaran: waktuPembayaran ?? this.waktuPembayaran,
      gunung: gunung ?? this.gunung,
      jalur: jalur ?? this.jalur,
      userId: userId ?? this.userId,
      paymentType: paymentType ?? this.paymentType,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pesananId,
        status,
        waktuPembayaran,
        gunung,
        jalur,
        userId,
        paymentType,
        paymentMethodName,
      ];
}
