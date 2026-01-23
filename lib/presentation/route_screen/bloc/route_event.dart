part of 'route_bloc.dart';

/// Abstract class for all events that can be dispatched from the Route widget.
/// Events must be immutable and implement the [Equatable] interface.
class RouteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Route widget is first created.
class RouteInitialEvent extends RouteEvent {
  final int idGunung; // Tambahkan properti idGunung
  final int jalurId;

  RouteInitialEvent({required this.idGunung, required this.jalurId});

  @override
  List<Object?> get props => [idGunung, jalurId];
}

/// Event that is dispatched to fetch Jalur details from the API.
// class FetchRouteCentresEvent extends RouteEvent {
//   final int idGunung;
//   final int jalurId;

//   FetchRouteCentresEvent({required this.idGunung, required this.jalurId});

//   @override
//   List<Object?> get props => [idGunung, jalurId];
// }
