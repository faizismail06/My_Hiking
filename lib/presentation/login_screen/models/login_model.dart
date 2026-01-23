import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [login_screen],
/// and is typically used to hold data that is passed between
/// different parts of the application.
class LoginModel extends Equatable {
  const LoginModel();

  LoginModel copyWith() {
    return const LoginModel();
  }

  @override
  List<Object?> get props => [];
}
