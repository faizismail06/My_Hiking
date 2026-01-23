part of 'landing_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Landing widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class LandingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Landing widget is first created.
class LandingInitialEvent extends LandingEvent {
  @override
  List<Object?> get props => [];
}
