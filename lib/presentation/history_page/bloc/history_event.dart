part of 'history_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// History widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the History widget is first created.
class HistoryInitialEvent extends HistoryEvent {
  @override
  List<Object?> get props => [];
}

// Event baru untuk mengirimkan userId
class HistoryUserIdEvent extends HistoryEvent {
  final String userId;

  HistoryUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChangeStatusEvent extends HistoryEvent {
  final String historyId;

  ChangeStatusEvent(this.historyId);
  @override
  List<Object?> get props => [historyId];
}
