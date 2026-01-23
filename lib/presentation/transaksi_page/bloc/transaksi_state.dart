part of 'transaksi_bloc.dart';

class TransaksiState extends Equatable {
  final TransaksiModel? transaksiModelObj;
  final String? userId;
  final bool isLoading;
  final String? error;

  const TransaksiState({
    this.transaksiModelObj,
    this.userId,
    this.isLoading = false,
    this.error,
  });

  TransaksiState copyWith({
    TransaksiModel? transaksiModelObj,
    String? userId,
    bool? isLoading,
    String? error,
  }) {
    return TransaksiState(
      transaksiModelObj: transaksiModelObj ?? this.transaksiModelObj,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [transaksiModelObj, userId, isLoading, error];
}