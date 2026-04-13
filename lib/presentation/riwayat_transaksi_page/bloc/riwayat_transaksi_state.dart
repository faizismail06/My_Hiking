part of 'riwayat_transaksi_bloc.dart';

class RiwayatTransaksiState extends Equatable {
  final List<TiketItemModel> completedHikesList;
  final List<TiketItemModel> historyOrdersList;
  final String? userId;
  final String? userName;
  final String? userTier;
  final String? userTierSource;
  final bool isLoading;
  final String errorMessage;

  const RiwayatTransaksiState({
    this.completedHikesList = const [],
    this.historyOrdersList = const [],
    this.userId,
    this.userName,
    this.userTier,
    this.userTierSource,
    this.isLoading = false,
    this.errorMessage = '',
  });

  RiwayatTransaksiState copyWith({
    List<TiketItemModel>? completedHikesList,
    List<TiketItemModel>? historyOrdersList,
    String? userId,
    String? userName,
    String? userTier,
    String? userTierSource,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RiwayatTransaksiState(
      completedHikesList: completedHikesList ?? this.completedHikesList,
      historyOrdersList: historyOrdersList ?? this.historyOrdersList,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userTier: userTier ?? this.userTier,
      userTierSource: userTierSource ?? this.userTierSource,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        completedHikesList,
        historyOrdersList,
        userId,
        userName,
        userTier,
        userTierSource,
        isLoading,
        errorMessage,
      ];
}
