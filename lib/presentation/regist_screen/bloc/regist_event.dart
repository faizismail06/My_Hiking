part of 'regist_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Regist widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class RegistEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Regist widget is first created.
class RegistInitialEvent extends RegistEvent {
  @override
  List<Object?> get props => [];
}

class TogglePassword2Visibility extends RegistEvent {
  @override
  List<Object?> get props => [];
}

class TogglePassword3Visibility extends RegistEvent {
  @override
  List<Object?> get props => [];
}
