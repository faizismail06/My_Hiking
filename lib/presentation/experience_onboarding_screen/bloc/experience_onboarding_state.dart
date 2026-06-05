class ExperienceOnboardingState {
  final bool isSubmitting;
  final int currentStep;
  final Map<String, int> answers;

  const ExperienceOnboardingState({
    this.isSubmitting = false,
    this.currentStep = 0,
    this.answers = const {},
  });

  ExperienceOnboardingState copyWith({
    bool? isSubmitting,
    int? currentStep,
    Map<String, int>? answers,
  }) {
    return ExperienceOnboardingState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
    );
  }
}
