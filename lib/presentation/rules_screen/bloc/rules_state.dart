part of 'rules_bloc.dart';

class RulesState extends Equatable {
  final List<RuleModel> rules;
  final bool isLoading;
  final String? errorMessage;

  const RulesState({
    this.rules = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [rules, isLoading, errorMessage];

  RulesState copyWith({
    List<RuleModel>? rules,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RulesState(
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
