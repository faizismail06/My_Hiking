part of 'profile_bloc.dart';

/// Represents the state of Profile in the application.
// ignore_for_file: must_be_immutable
class ProfileState extends Equatable {
  const ProfileState({this.profileModelObj});

  final ProfileModel? profileModelObj;

  @override
  List<Object?> get props => [profileModelObj];

  /// Creates a copy of the current [ProfileState] with optional new values.
  ProfileState copyWith({ProfileModel? profileModelObj}) {
    return ProfileState(
      profileModelObj: profileModelObj ?? this.profileModelObj,
    );
  }
}
