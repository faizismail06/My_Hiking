part of 'payment_method_bloc.dart';

// Abstract class for all events
abstract class PaymentMethodEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Event untuk inisialisasi state pertama kali
class PaymentMethodInitialEvent extends PaymentMethodEvent {}

class FetchPaymentsEvent extends PaymentMethodEvent {}

// Event ketika metode pembayaran dipilih
class PaymentmethodslistItemEvent extends PaymentMethodEvent {
  final int index; // Index pilihan metode pembayaran

  PaymentmethodslistItemEvent({required this.index});

  @override
  List<Object?> get props => [index];
}
