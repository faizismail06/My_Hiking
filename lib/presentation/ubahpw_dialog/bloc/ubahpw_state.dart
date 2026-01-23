part of 'ubahpw_bloc.dart';

/// Represents the state of Ubahpw in the application.
// ignore_for_file: must_be_immutable
class UbahpwState extends Equatable {
  UbahpwState({
    this.currentPasswordInputController,
    this.newPasswordInputController,
    this.confirmPasswordInputController,
    this.ubahpwModelObj,
  });

  TextEditingController? currentPasswordInputController;
  TextEditingController? newPasswordInputController;
  TextEditingController? confirmPasswordInputController;
  UbahpwModel? ubahpwModelObj;

  @override
  List<Object?> get props => [
        currentPasswordInputController,
        newPasswordInputController,
        confirmPasswordInputController,
        ubahpwModelObj,
      ];

  UbahpwState copyWith({
    TextEditingController? currentPasswordInputController,
    TextEditingController? newPasswordInputController,
    TextEditingController? confirmPasswordInputController,
    UbahpwModel? ubahpwModelObj,
  }) {
    return UbahpwState(
      currentPasswordInputController:
          currentPasswordInputController ?? this.currentPasswordInputController,
      newPasswordInputController:
          newPasswordInputController ?? this.newPasswordInputController,
      confirmPasswordInputController:
          confirmPasswordInputController ?? this.confirmPasswordInputController,
      ubahpwModelObj: ubahpwModelObj ?? this.ubahpwModelObj,
    );
  }
}
