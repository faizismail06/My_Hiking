part of 'landing_bloc.dart';

/// Represents the state of Landing in the application.
// ignore_for_file: must_be_immutable
class LandingState extends Equatable {
  const LandingState({this.landingModelObj});

  final LandingModel? landingModelObj;

  @override
  List<Object?> get props => [landingModelObj];

  LandingState copyWith({LandingModel? landingModelObj}) {
    return LandingState(
      landingModelObj: landingModelObj ?? this.landingModelObj,
    );
  }
}


