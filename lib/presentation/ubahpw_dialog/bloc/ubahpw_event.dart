part of 'ubahpw_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Ubahpw widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class UbahpwEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Ubahpw widget is first created.
class UbahpwInitialEvent extends UbahpwEvent {
  @override
  List<Object?> get props => [];
}
