part of 'reset_page_two_bloc.dart';

/// Represents the state of ResetPageTwo in the application.
// ignore_for_file: must_be_immutable
class ResetPageTwoState extends Equatable {
  ResetPageTwoState({
    this.passwordController,
    this.passwordoneController,
    this.resetPageTwoModelObj,
  });

  TextEditingController? passwordController;
  TextEditingController? passwordoneController;
  ResetPageTwoModel? resetPageTwoModelObj;

  @override
  List<Object?> get props => [
        passwordController,
        passwordoneController,
        resetPageTwoModelObj,
      ];

  ResetPageTwoState copyWith({
    TextEditingController? passwordController,
    TextEditingController? passwordoneController,
    ResetPageTwoModel? resetPageTwoModelObj,
  }) {
    return ResetPageTwoState(
      passwordController: passwordController ?? this.passwordController,
      passwordoneController: passwordoneController ?? this.passwordoneController,
      resetPageTwoModelObj: resetPageTwoModelObj ?? this.resetPageTwoModelObj,
    );
  }
}
