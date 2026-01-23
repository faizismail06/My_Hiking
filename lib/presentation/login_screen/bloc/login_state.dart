part of 'login_bloc.dart';

/// Represents the state of Login in the application.
// ignore_for_file: must_be_immutable
class LoginState extends Equatable {
  LoginState({
    this.lockoneController,
    this.locationoneController,
    this.isShowPassword = true,
    this.loginModelObj,
  });

  TextEditingController? lockoneController;
  TextEditingController? locationoneController;
  LoginModel? loginModelObj;
  bool isShowPassword;

  @override
  List<Object?> get props => [
        lockoneController,
        locationoneController,
        isShowPassword,
        loginModelObj,
      ];

  LoginState copyWith({
    TextEditingController? lockoneController,
    TextEditingController? locationoneController,
    bool? isShowPassword,
    LoginModel? loginModelObj,
  }) {
    return LoginState(
      lockoneController: lockoneController ?? this.lockoneController,
      locationoneController: locationoneController ?? this.locationoneController,
      isShowPassword: isShowPassword ?? this.isShowPassword,
      loginModelObj: loginModelObj ?? this.loginModelObj,
    );
  }
}
