part of 'payment_method_bloc.dart';

// Represents the state of PaymentMethod in the application.
class PaymentMethodState extends Equatable {
  final PaymentMethodModel? paymentMethodModelObj;
  final bool isLoading; // Untuk menunjukkan status loading
  final String? error; // Untuk menyimpan pesan error
  const PaymentMethodState({
    this.paymentMethodModelObj,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [paymentMethodModelObj, isLoading, error];

  PaymentMethodState copyWith({
    PaymentMethodModel? paymentMethodModelObj,
    bool? isLoading,
    String? error,
  }) {
    return PaymentMethodState(
      paymentMethodModelObj:
          paymentMethodModelObj ?? this.paymentMethodModelObj,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
