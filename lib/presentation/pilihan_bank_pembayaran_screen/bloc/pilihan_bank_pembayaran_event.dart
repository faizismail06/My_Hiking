part of 'pilihan_bank_pembayaran_bloc.dart';

// Abstract class for all events
abstract class PilihanBankPembayaranEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Event untuk inisialisasi state pertama kali
class PilihanBankPembayaranInitialEvent extends PilihanBankPembayaranEvent {}

class FetchPaymentsEvent extends PilihanBankPembayaranEvent {}

// Event ketika metode pembayaran dipilih
class PaymentmethodslistItemEvent extends PilihanBankPembayaranEvent {
  final int index; // Index pilihan metode pembayaran

  PaymentmethodslistItemEvent({required this.index});

  @override
  List<Object?> get props => [index];
}
