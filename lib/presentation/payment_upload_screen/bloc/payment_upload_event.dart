part of 'payment_upload_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// PaymentUpload widget.
/// Events must be immutable and implement the [Equatable] interface.
class PaymentUploadEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that triggers fetching the payment upload data.
class FetchPaymentUploadEvent extends PaymentUploadEvent {
  final String transactionId;
  String? filePath;
  final bool isLoading;
  final String? error;

  FetchPaymentUploadEvent({
    required this.transactionId,
    this.filePath,
    required this.isLoading,
    this.error,
  });

  @override
  List<Object?> get props => [transactionId, filePath, isLoading, error];
}
