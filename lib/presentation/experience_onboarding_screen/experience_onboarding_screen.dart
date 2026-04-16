import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/experience_onboarding_screen/bloc/experience_onboarding_cubit.dart';
import 'package:myhiking/presentation/experience_onboarding_screen/bloc/experience_onboarding_state.dart';
import 'package:myhiking/presentation/experience_onboarding_screen/experience_questions.dart';
import '../../core/app_export.dart';

class ExperienceOnboardingScreen extends StatefulWidget {
  const ExperienceOnboardingScreen({super.key});

  @override
  State<ExperienceOnboardingScreen> createState() =>
      _ExperienceOnboardingScreenState();
}

class _ExperienceOnboardingScreenState extends State<ExperienceOnboardingScreen> {
  final ExperienceOnboardingCubit _cubit = ExperienceOnboardingCubit();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_cubit.isQuestionnaireComplete) {
      _showSnack('Harap jawab semua pertanyaan terlebih dahulu.');
      return;
    }

    final frequencyScore = _cubit.state.answers['frequency'] ?? 0;
    final jumlahPendakian = _mapFrequencyScoreToJumlahPendakian(frequencyScore);
    final jumlahSummit = _deriveJumlahSummit(jumlahPendakian, frequencyScore);
    final totalWeightedScore = _cubit.calculateTotalWeightedScore();

    _cubit.setSubmitting(true);

    try {
      final response = await ApiService().submitOnboardingExperience(
        jumlahPendakian: jumlahPendakian,
        jumlahSummit: jumlahSummit,
        questionnaireAnswers: _buildQuestionnaireAnswerPayload(),
        totalWeightedScore: totalWeightedScore,
      );

      if (!mounted) return;

      final data = (response['data'] as Map<String, dynamic>?) ?? {};
      final tier = data['tier']?.toString() ?? '-';
      final weightedTier = data['weighted_tier']?.toString() ?? tier;
      final weightedScore = data['weighted_score']?.toString() ?? '$totalWeightedScore';

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.verified_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Onboarding Berhasil')),
            ],
          ),
          content: Text(
            'Data pengalaman tersimpan.\nTier Anda: $tier\nSkor survey: $weightedScore\nTier survey: $weightedTier',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiActionException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Terjadi kesalahan saat menyimpan onboarding experience.');
    } finally {
      if (mounted) {
        _cubit.setSubmitting(false);
      }
    }
  }

  int _mapFrequencyScoreToJumlahPendakian(int score) {
    switch (score) {
      case 0:
        return 0;
      case 1:
        return 2;
      case 2:
        return 5;
      case 3:
        return 8;
      case 4:
        return 12;
      default:
        return 0;
    }
  }

  int _deriveJumlahSummit(int jumlahPendakian, int frequencyScore) {
    final ratioByScore = {
      0: 0.0,
      1: 0.5,
      2: 0.7,
      3: 0.8,
      4: 0.85,
    };

    final ratio = ratioByScore[frequencyScore] ?? 0.0;
    final result = (jumlahPendakian * ratio).round();
    return result.clamp(0, jumlahPendakian);
  }

  List<Map<String, dynamic>> _buildQuestionnaireAnswerPayload() {
    return kExperienceQuestions.map((question) {
      final selectedScore = _cubit.state.answers[question.id] ?? 0;
      final selectedOption = question.options.firstWhere(
        (option) => option.score == selectedScore,
        orElse: () => question.options.first,
      );

      final weightedScore =
          _cubit.calculateQuestionWeightedScore(score: selectedScore, weight: question.weight);

      return {
        'question_id': question.id,
        'question_title': question.title,
        'weight': question.weight,
        'selected_option_id': selectedOption.id,
        'selected_option_title': selectedOption.title,
        'score': selectedScore,
        'weighted_score': weightedScore,
      };
    }).toList();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ExperienceOnboardingCubit, ExperienceOnboardingState>(
        builder: (context, state) {
          final totalQuestions = kExperienceQuestions.length;
          final currentQuestion = kExperienceQuestions[state.currentStep];
          final selectedScore = state.answers[currentQuestion.id];
          final progressValue = (state.currentStep + 1) / totalQuestions;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Onboarding Experience'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.insights_rounded, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jawab 5 pertanyaan singkat untuk menentukan tier awal Anda.',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pertanyaan ${state.currentStep + 1} dari $totalQuestions',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progressValue,
                      color: const Color(0xFF1B734A),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentQuestion.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...currentQuestion.options.map((option) {
                    final isSelected = selectedScore == option.score;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _cubit.selectAnswer(currentQuestion.id, option.score),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEAF6F0) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1B734A)
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? const Color(0xFF1B734A)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  option.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? const Color(0xFF114A31)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (state.currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isSubmitting ? null : _cubit.previousStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B734A),
                              side: const BorderSide(color: Color(0xFF1B734A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Kembali'),
                          ),
                        ),
                      if (state.currentStep > 0) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () {
                                  if (!_cubit.canProceedCurrentStep()) {
                                    _showSnack('Pilih satu jawaban terlebih dahulu.');
                                    return;
                                  }

                                  if (_cubit.isLastStep) {
                                    _submit();
                                  } else {
                                    _cubit.nextStep();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B734A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_cubit.isLastStep ? 'Simpan Onboarding' : 'Lanjut'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
