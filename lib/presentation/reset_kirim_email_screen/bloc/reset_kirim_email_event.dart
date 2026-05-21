part of 'reset_kirim_email_bloc.dart';

/// Abstract class for all events that can be dispatched from the ResetKirimEmail widget.
///
/// Events must be immutable and implement the [Equatable] interface.
abstract class ResetKirimEmailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the ResetKirimEmail widget is first created.
class ResetKirimEmailInitialEvent extends ResetKirimEmailEvent {
  @override
  List<Object?> get props => [];
}
