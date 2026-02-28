part of 'history_bloc.dart';

/// Represents the state of History in the application.
// ignore_for_file: must_be_immutable
class HistoryState extends Equatable {
  final HistoryModel? historyModelObj;
  final String? userId;
  final String errorMessage;

  HistoryState({
    this.historyModelObj,
    this.userId,
    this.errorMessage = '',
  });

  HistoryState copyWith({
    HistoryModel? historyModelObj,
    String? userId,
    String? errorMessage,
  }) {
    return HistoryState(
      historyModelObj: historyModelObj ?? this.historyModelObj,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [historyModelObj, userId, errorMessage];
}
