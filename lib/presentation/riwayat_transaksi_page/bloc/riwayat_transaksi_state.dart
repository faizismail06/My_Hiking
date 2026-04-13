part of 'riwayat_transaksi_bloc.dart';

class RiwayatTransaksiState extends Equatable {
  final List<TiketItemModel> completedHikesList;
  final String? userId;
  final String? userName;
  final String? userTier;
  final String? userTierSource;
  final bool isLoading;
  final String errorMessage;

  const RiwayatTransaksiState({
    this.completedHikesList = const [],
    this.userId,
    this.userName,
    this.userTier,
    this.userTierSource,
    this.isLoading = false,
    this.errorMessage = '',
  });

  RiwayatTransaksiState copyWith({
    List<TiketItemModel>? completedHikesList,
    String? userId,
    String? userName,
    String? userTier,
    String? userTierSource,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RiwayatTransaksiState(
      completedHikesList: completedHikesList ?? this.completedHikesList,
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
        userId,
        userName,
        userTier,
        userTierSource,
        isLoading,
        errorMessage,
      ];
}
