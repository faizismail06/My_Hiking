part of 'pop_up_checkout_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// PopUpCheckout widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class PopUpCheckoutEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the PopUpCheckout widget is first created.
class PopUpCheckoutInitialEvent extends PopUpCheckoutEvent {
  @override
  List<Object?> get props => [];
}
