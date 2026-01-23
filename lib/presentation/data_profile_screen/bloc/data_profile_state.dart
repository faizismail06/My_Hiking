part of 'data_profile_bloc.dart';

/// Represents the state of DataProfile in the application.
//
/// ignore_for_file: must_be_immutable
class DataProfileState extends Equatable {
  final TextEditingController? fullNameInputController;
  final TextEditingController? nikInputController;
  final TextEditingController? phoneNumberInputController;
  final TextEditingController? emergencyContactInputController;
  final TextEditingController? addressInputController;
  final TextEditingController? emailInputController;
  TextEditingController? dateOfBirthController;
  final TextEditingController? oldPasswordController;
  final TextEditingController? newPasswordController;
  final TextEditingController? confirmPasswordController;
  final bool isEmailValid;
  final String? statusMessage;
  final bool isLoading;
  final String error;

  DataProfileState({
    this.fullNameInputController,
    this.nikInputController,
    this.phoneNumberInputController,
    this.emergencyContactInputController,
    this.addressInputController,
    this.emailInputController,
    this.dateOfBirthController,
    this.oldPasswordController,
    this.newPasswordController,
    this.confirmPasswordController,
    this.isEmailValid = true,
    this.statusMessage,
    this.isLoading = false,
    this.error = '',
  });

  DataProfileState copyWith({
    TextEditingController? fullNameInputController,
    TextEditingController? nikInputController,
    TextEditingController? phoneNumberInputController,
    TextEditingController? emergencyContactInputController,
    TextEditingController? addressInputController,
    TextEditingController? emailInputController,
    TextEditingController? dateOfBirthController,
    TextEditingController? oldPasswordController,
    TextEditingController? newPasswordController,
    TextEditingController? confirmPasswordController,
    bool? isEmailValid,
    String? statusMessage,
    bool? isLoading,
    String? error,
  }) {
    return DataProfileState(
      fullNameInputController:
          fullNameInputController ?? this.fullNameInputController,
      nikInputController: nikInputController ?? this.nikInputController,
      phoneNumberInputController:
          phoneNumberInputController ?? this.phoneNumberInputController,
      emergencyContactInputController: emergencyContactInputController ??
          this.emergencyContactInputController,
      addressInputController:
          addressInputController ?? this.addressInputController,
      emailInputController: emailInputController ?? this.emailInputController,
      dateOfBirthController:
          dateOfBirthController ?? this.dateOfBirthController,
      oldPasswordController:
          oldPasswordController ?? this.oldPasswordController,
      newPasswordController:
          newPasswordController ?? this.newPasswordController,
      confirmPasswordController:
          confirmPasswordController ?? this.confirmPasswordController,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      statusMessage: statusMessage ?? this.statusMessage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        fullNameInputController,
        nikInputController,
        phoneNumberInputController,
        emergencyContactInputController,
        addressInputController,
        emailInputController,
        dateOfBirthController,
        oldPasswordController,
        newPasswordController,
        confirmPasswordController,
        isEmailValid,
        statusMessage,
        isLoading,
        error,
      ];
}
