import 'package:flutter_bloc/flutter_bloc.dart';

import '../experience_questions.dart';
import 'experience_onboarding_state.dart';

class ExperienceOnboardingCubit extends Cubit<ExperienceOnboardingState> {
  ExperienceOnboardingCubit() : super(const ExperienceOnboardingState());

  void setSubmitting(bool value) {
    emit(state.copyWith(isSubmitting: value));
  }

  void selectAnswer(String questionId, int score) {
    final updatedAnswers = Map<String, int>.from(state.answers)
      ..[questionId] = score;
    emit(state.copyWith(answers: updatedAnswers));
  }

  bool canProceedCurrentStep() {
    final question = kExperienceQuestions[state.currentStep];
    return state.answers.containsKey(question.id);
  }

  void nextStep() {
    if (state.currentStep >= kExperienceQuestions.length - 1) {
      return;
    }
    emit(state.copyWith(currentStep: state.currentStep + 1));
  }

  void previousStep() {
    if (state.currentStep <= 0) {
      return;
    }
    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  bool get isLastStep => state.currentStep == kExperienceQuestions.length - 1;

  int calculateQuestionWeightedScore({
    required int score,
    required int weight,
  }) {
    return ((score / 4) * weight).round();
  }

  int calculateTotalWeightedScore() {
    var total = 0;
    for (final question in kExperienceQuestions) {
      final score = state.answers[question.id] ?? 0;
      total += calculateQuestionWeightedScore(score: score, weight: question.weight);
    }
    return total;
  }

  bool get isQuestionnaireComplete {
    return state.answers.length == kExperienceQuestions.length;
  }
}
