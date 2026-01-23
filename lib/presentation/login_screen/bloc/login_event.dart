part of 'login_bloc.dart';

/// Abstract class for all events that can be dispatched from the Login widget.
/// Events must be immutable and implement the [Equatable] interface.
class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Login widget is first created.
class LoginInitialEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}

/// Event for changing password visibility.
// ignore_for_file: must_be_immutable
class ChangePasswordVisibilityEvent extends LoginEvent {
  ChangePasswordVisibilityEvent({required this.value});
  
  final bool value;

  @override
  List<Object?> get props => [value];
}
