part of 'order_cancelled_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// OrderCancelled widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class OrderCancelledEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the OrderCancelled widget is
/// first created.
class OrderCancelledInitialEvent extends OrderCancelledEvent {
  @override
  List<Object?> get props => [];
}
