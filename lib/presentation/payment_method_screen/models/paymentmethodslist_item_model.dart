import 'package:equatable/equatable.dart';

class PaymentmethodslistItemModel extends Equatable {
  const PaymentmethodslistItemModel({
    this.namaPayment,
    this.gambarPayment,
    this.radioGroup,
    this.id,
  });

  final String? namaPayment;
  final String? gambarPayment;
  final String? radioGroup;
  final int? id;

  PaymentmethodslistItemModel copyWith({
    String? namaPayment,
    String? gambarPayment,
    String? radioGroup,
    int? id,
  }) {
    return PaymentmethodslistItemModel(
      namaPayment: namaPayment ?? this.namaPayment,
      gambarPayment: gambarPayment ?? this.gambarPayment,
      radioGroup: radioGroup ?? this.radioGroup,
      id: id ?? this.id,
    );
  }

  /// Getter untuk menghasilkan path gambar lengkap.
  String get imagePath {
    const baseUrl = 'http://127.0.0.1:8000/storage';
    return (gambarPayment != null && gambarPayment!.isNotEmpty)
        ? '$baseUrl/$gambarPayment'
        : '';
  }

  @override
  List<Object?> get props => [
        namaPayment,
        gambarPayment,
        radioGroup,
        id,
      ];
}
