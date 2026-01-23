import 'package:equatable/equatable.dart';
import 'paymentmethodslist_item_model.dart';

class PilihanBankPembayaranModel extends Equatable {
  final List<PaymentmethodslistItemModel> paymentmethodslistItemList;
  final int? selectedPaymentMethodIndex;

  PilihanBankPembayaranModel({
    List<PaymentmethodslistItemModel>? paymentmethodslistItemList,
    this.selectedPaymentMethodIndex,
  }) : paymentmethodslistItemList = paymentmethodslistItemList ?? const [];

  PilihanBankPembayaranModel copyWith({
    List<PaymentmethodslistItemModel>? paymentmethodslistItemList,
    int? selectedPaymentMethodIndex,
  }) {
    return PilihanBankPembayaranModel(
      paymentmethodslistItemList:
          paymentmethodslistItemList ?? this.paymentmethodslistItemList,
      selectedPaymentMethodIndex:
          selectedPaymentMethodIndex ?? this.selectedPaymentMethodIndex,
    );
  }

  @override
  List<Object?> get props =>
      [paymentmethodslistItemList, selectedPaymentMethodIndex];
}
