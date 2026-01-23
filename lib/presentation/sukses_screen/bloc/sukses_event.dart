part of 'sukses_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Sukses widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class SuksesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Sukses widget is first created.
class SuksesInitialEvent extends SuksesEvent {
  @override
  List<Object?> get props => [];
}
