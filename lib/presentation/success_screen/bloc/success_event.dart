part of 'success_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Success widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class SuccessEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Success widget is first created.
class SuccessInitialEvent extends SuccessEvent {
  @override
  List<Object?> get props => [];
}
