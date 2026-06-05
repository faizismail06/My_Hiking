part of 'reset_kirim_email_bloc.dart';

/// Represents the state of ResetKirimEmail in the application.
// ignore_for_file: must_be_immutable
class ResetKirimEmailState extends Equatable {
  ResetKirimEmailState({this.passwordController, this.resetKirimEmailModelObj});

  TextEditingController? passwordController;
  ResetKirimEmailModel? resetKirimEmailModelObj;

  @override
  List<Object?> get props => [passwordController, resetKirimEmailModelObj];

  ResetKirimEmailState copyWith({
    TextEditingController? passwordController,
    ResetKirimEmailModel? resetKirimEmailModelObj,
  }) {
    return ResetKirimEmailState(
      passwordController: passwordController ?? this.passwordController,
      resetKirimEmailModelObj:
          resetKirimEmailModelObj ?? this.resetKirimEmailModelObj,
    );
  }
}
