import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [profile_screen],
/// and is typically used to hold data that is passed between different parts of the application.
class ProfileModel extends Equatable {
  const ProfileModel();

  /// Creates a copy of the current ProfileModel instance.
  ProfileModel copyWith() {
    return const ProfileModel();
  }

  @override
  List<Object?> get props => [];
}
