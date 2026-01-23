part of 'reset_page_two_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// ResetPageTwo widget.
///
/// Events must be immutable and implement the [Equatable] interface.
abstract class ResetPageTwoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the ResetPageTwo widget is first created.
class ResetPageTwoInitialEvent extends ResetPageTwoEvent {
  @override
  List<Object?> get props => [];
}
