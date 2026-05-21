part of 'regist_bloc.dart';

/// Represents the state of Regist in the application.
// ignore_for_file: must_be_immutable
class RegistState extends Equatable {
  RegistState({
    this.edittextoneController,
    this.emailtwoController,
    this.passwordtwoController,
    this.passwordthreeController,
    this.registModelObj,
    this.isPassword2Visible,
    this.isPassword3Visible,
  });

  TextEditingController? edittextoneController;
  TextEditingController? emailtwoController;
  TextEditingController? passwordtwoController;
  TextEditingController? passwordthreeController;
  bool? isPassword2Visible;
  bool? isPassword3Visible;
  RegistModel? registModelObj;

  RegistState copyWith({
    TextEditingController? edittextoneController,
    TextEditingController? emailtwoController,
    TextEditingController? passwordtwoController,
    TextEditingController? passwordthreeController,
    bool? isPassword2Visible,
    bool? isPassword3Visible,
    RegistModel? registModelObj,
  }) {
    return RegistState(
      edittextoneController:
          edittextoneController ?? this.edittextoneController,
      emailtwoController: emailtwoController ?? this.emailtwoController,
      passwordtwoController:
          passwordtwoController ?? this.passwordtwoController,
      passwordthreeController:
          passwordthreeController ?? this.passwordthreeController,
      isPassword2Visible: isPassword2Visible ?? this.isPassword2Visible,
      isPassword3Visible: isPassword3Visible ?? this.isPassword3Visible,
      registModelObj: registModelObj ?? this.registModelObj,
    );
  }

  @override
  List<Object?> get props => [
        edittextoneController,
        emailtwoController,
        passwordtwoController,
        passwordthreeController,
        isPassword2Visible,
        isPassword3Visible,
        registModelObj,
      ];
}
