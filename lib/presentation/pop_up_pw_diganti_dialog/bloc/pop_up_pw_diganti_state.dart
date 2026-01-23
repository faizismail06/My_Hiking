part of 'pop_up_pw_diganti_bloc.dart';

/// Represents the state of PopUpPwDiganti in the application.

// ignore_for_file: must_be_immutable
class PopUpPwDigantiState extends Equatable {
  PopUpPwDigantiState({this.popUpPwDigantiModelObj});

  PopUpPwDigantiModel? popUpPwDigantiModelObj;

  @override
  List<Object?> get props => [popUpPwDigantiModelObj];

  PopUpPwDigantiState copyWith({PopUpPwDigantiModel? popUpPwDigantiModelObj}) {
    return PopUpPwDigantiState(
      popUpPwDigantiModelObj:
          popUpPwDigantiModelObj ?? this.popUpPwDigantiModelObj,
    );
  }
}
