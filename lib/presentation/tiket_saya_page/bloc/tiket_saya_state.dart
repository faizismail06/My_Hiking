part of 'tiket_saya_bloc.dart';

class TiketSayaState extends Equatable {
  final TiketSayaModel? tiketSayaModelObj;
  final Map<int, TransaksiItemModel>? transactionMap;
  final String? userId;
  final String? userName;
  final String? userTier;
  final String? userTierSource;
  final bool isLoading;
  final String errorMessage;

  const TiketSayaState({
    this.tiketSayaModelObj,
    this.transactionMap,
    this.userId,
    this.userName,
    this.userTier,
    this.userTierSource,
    this.isLoading = false,
    this.errorMessage = '',
  });

  TiketSayaState copyWith({
    TiketSayaModel? tiketSayaModelObj,
    Map<int, TransaksiItemModel>? transactionMap,
    String? userId,
    String? userName,
    String? userTier,
    String? userTierSource,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TiketSayaState(
      tiketSayaModelObj: tiketSayaModelObj ?? this.tiketSayaModelObj,
      transactionMap: transactionMap ?? this.transactionMap,
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
        tiketSayaModelObj,
        transactionMap,
        userId,
        userName,
        userTier,
        userTierSource,
        isLoading,
        errorMessage,
      ];
}
