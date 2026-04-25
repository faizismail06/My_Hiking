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

class HomeRefreshEvent extends HomeEvent {
  final Completer<void>? completer;

  HomeRefreshEvent({this.completer});

  @override
  List<Object?> get props => [completer];
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

/// Dispatched after the user submits the DssPreferenceScreen.
/// Triggers a fresh recommendation fetch using the chosen priority weights.
class HomeFetchWithWeightsEvent extends HomeEvent {
  /// Priority weight map using backend keys, e.g.:
  ///   { 'priority_cost': 4.0, 'priority_panorama': 5.0, ... }
  final Map<String, double> weights;

  HomeFetchWithWeightsEvent({required this.weights});

  @override
  List<Object?> get props => [weights];
}
