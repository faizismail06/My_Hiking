part of 'tata_tertib_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// TataTertib widget.
///
/// Events must be immutable and implement the [Equatable] interface.
abstract class TataTertibEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TataTertibInitialEvent extends TataTertibEvent {
  final int? jalurId;

  TataTertibInitialEvent(this.jalurId);

  @override
  List<Object?> get props => [jalurId];
}

class LoadTataTertibEvent extends TataTertibEvent {
  final int jalurId;

  LoadTataTertibEvent(this.jalurId);

  @override
  List<Object?> get props => [jalurId];
}