part of 'transaction_bloc.dart';

class TransactionState extends Equatable {
  final TransactionModel? transactionModelObj;
  final String? userId;
  final bool isLoading;
  final String? error;

  const TransactionState({
    this.transactionModelObj,
    this.userId,
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    TransactionModel? transactionModelObj,
    String? userId,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactionModelObj: transactionModelObj ?? this.transactionModelObj,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [transactionModelObj, userId, isLoading, error];
}
