part of 'trail_bloc.dart';

/// Abstract class for all events that can be dispatched from the Trail widget.
/// Events must be immutable and implement the [Equatable] interface.
class TrailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Trail widget is first created.
class TrailInitialEvent extends TrailEvent {
  final int idGunung; // Tambahkan properti idGunung
  final int jalurId;

  TrailInitialEvent({required this.idGunung, required this.jalurId});

  @override
  List<Object?> get props => [idGunung, jalurId];
}

/// Event that is dispatched to fetch Jalur details from the API.
// class FetchTrailCentresEvent extends TrailEvent {
//   final int idGunung;
//   final int jalurId;

//   FetchTrailCentresEvent({required this.idGunung, required this.jalurId});

//   @override
//   List<Object?> get props => [idGunung, jalurId];
// }
