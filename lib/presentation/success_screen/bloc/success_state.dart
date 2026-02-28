part of 'success_bloc.dart';

/// Represents the state of Success in the application.
// ignore_for_file: must_be_immutable
class SuccessState extends Equatable {
  SuccessState({this.successModelObj});

  SuccessModel? successModelObj;

  @override
  List<Object?> get props => [successModelObj];

  SuccessState copyWith({SuccessModel? successModelObj}) {
    return SuccessState(
      successModelObj: successModelObj ?? this.successModelObj,
    );
  }
}
