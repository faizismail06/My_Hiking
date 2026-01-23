part of 'beranda_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Beranda widget.
/// 
/// Events must be immutable and implement the [Equatable] interface.
class BerandaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Beranda widget is first created.
class BerandaInitialEvent extends BerandaEvent {
  @override
  List<Object?> get props => [];
}

class BerandaSearchEvent extends BerandaEvent {
  final String query;

  BerandaSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}