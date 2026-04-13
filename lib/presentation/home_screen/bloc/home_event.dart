part of 'home_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Home widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Home widget is first created.
class HomeInitialEvent extends HomeEvent {
  @override
  List<Object?> get props => [];
}

class HomeSearchEvent extends HomeEvent {
  final String query;

  HomeSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class HomeFilterProvinceEvent extends HomeEvent {
  final String? province;

  HomeFilterProvinceEvent({this.province});

  @override
  List<Object?> get props => [province];
}
