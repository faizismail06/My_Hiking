part of 'transaction_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Transaction widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Transaction widget is first created.
class TransactionInitialEvent extends TransactionEvent {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the user ID is received
class TransactionUserIdEvent extends TransactionEvent {
  final String userId;

  TransactionUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChangeStatusEvent extends TransactionEvent {
  final String transactionId; // ID transaksi yang ingin diubah

  ChangeStatusEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
