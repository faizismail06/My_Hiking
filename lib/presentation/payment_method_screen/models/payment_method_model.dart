import 'package:equatable/equatable.dart';
import 'paymentmethodslist_item_model.dart';

class PaymentMethodModel extends Equatable {
  final List<PaymentmethodslistItemModel> paymentmethodslistItemList;
  final int? selectedPaymentMethodIndex;

  PaymentMethodModel({
    List<PaymentmethodslistItemModel>? paymentmethodslistItemList,
    this.selectedPaymentMethodIndex,
  }) : paymentmethodslistItemList = paymentmethodslistItemList ?? const [];

  PaymentMethodModel copyWith({
    List<PaymentmethodslistItemModel>? paymentmethodslistItemList,
    int? selectedPaymentMethodIndex,
  }) {
    return PaymentMethodModel(
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
