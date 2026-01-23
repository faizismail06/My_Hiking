part of 'pilihan_bank_pembayaran_bloc.dart';

// Represents the state of PilihanBankPembayaran in the application.
class PilihanBankPembayaranState extends Equatable {
  final PilihanBankPembayaranModel? pilihanBankPembayaranModelObj;
  final bool isLoading; // Untuk menunjukkan status loading
  final String? error; // Untuk menyimpan pesan error
  const PilihanBankPembayaranState({
    this.pilihanBankPembayaranModelObj,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [pilihanBankPembayaranModelObj, isLoading, error];

  PilihanBankPembayaranState copyWith({
    PilihanBankPembayaranModel? pilihanBankPembayaranModelObj,
    bool? isLoading,
    String? error,
  }) {
    return PilihanBankPembayaranState(
      pilihanBankPembayaranModelObj:
          pilihanBankPembayaranModelObj ?? this.pilihanBankPembayaranModelObj,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
