import 'package:flutter_bloc/flutter_bloc.dart';

import 'experience_onboarding_state.dart';

class ExperienceOnboardingCubit extends Cubit<ExperienceOnboardingState> {
  ExperienceOnboardingCubit() : super(const ExperienceOnboardingState());

  void setSubmitting(bool value) {
    emit(state.copyWith(isSubmitting: value));
  }
}
