class ExperienceOnboardingState {
  final bool isSubmitting;

  const ExperienceOnboardingState({
    this.isSubmitting = false,
  });

  ExperienceOnboardingState copyWith({
    bool? isSubmitting,
  }) {
    return ExperienceOnboardingState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
