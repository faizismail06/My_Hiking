part of 'tata_tertib_bloc.dart';

class TataTertibState extends Equatable {
  final List<TataTertibModel> tataTertibs;
  final bool isLoading;
  final String? errorMessage;

  const TataTertibState({
    this.tataTertibs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [tataTertibs, isLoading, errorMessage];

  TataTertibState copyWith({
    List<TataTertibModel>? tataTertibs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TataTertibState(
      tataTertibs: tataTertibs ?? this.tataTertibs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
