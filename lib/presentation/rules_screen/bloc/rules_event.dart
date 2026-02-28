part of 'rules_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// Rules widget.
///
/// Events must be immutable and implement the [Equatable] interface.
abstract class RulesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RulesInitialEvent extends RulesEvent {
  final int? jalurId;

  RulesInitialEvent(this.jalurId);

  @override
  List<Object?> get props => [jalurId];
}

class LoadRulesEvent extends RulesEvent {
  final int jalurId;

  LoadRulesEvent(this.jalurId);

  @override
  List<Object?> get props => [jalurId];
}
