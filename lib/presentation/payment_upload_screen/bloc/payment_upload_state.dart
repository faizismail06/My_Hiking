part of 'payment_upload_bloc.dart';

/// Represents the state of PaymentUpload in the application.
// ignore_for_file: must_be_immutable
class PaymentUploadState extends Equatable {
  final PaymentUploadModel? paymentUploadModelObj;
  final bool isLoading;
  final String error;

  // Constructor with optional parameters.
  PaymentUploadState({
    this.paymentUploadModelObj,
    this.isLoading = false,
    this.error = '',
  });

  // Initial state factory
  factory PaymentUploadState.initial() {
    return PaymentUploadState(
      isLoading: false,
      error: '',
      paymentUploadModelObj: null,
    );
  }

  // Helper method to create a new state with modified values
  PaymentUploadState copyWith({
    bool? isLoading,
    String? error,
    PaymentUploadModel? paymentUploadModelObj,
  }) {
    return PaymentUploadState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      paymentUploadModelObj: paymentUploadModelObj ??
          this.paymentUploadModelObj,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, error, paymentUploadModelObj];
}
