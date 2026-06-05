part of 'trail_bloc.dart';

/// Represents the state of Trail in the application.
class TrailState extends Equatable {
  final String? error; // Untuk menyimpan pesan error
  final bool isLoading; // Menandai apakah data sedang dimuat
  final Jalur? jalur; // Detail jalur yang diambil dari API
  final Gunung? gunung; // Detail gunung terkait
  final String? errorMessage; // Pesan error jika ada masalah
  final DssEvaluation? dss; // Evaluasi DSS dari backend

  const TrailState({
    this.error,
    this.isLoading = false,
    this.jalur,
    this.gunung,
    this.errorMessage,
    this.dss,
  });

  /// Copy state dengan nilai baru (immutable)
  TrailState copyWith({
    String? error,
    bool? isLoading,
    Jalur? jalur,
    Gunung? gunung,
    String? errorMessage,
    DssEvaluation? dss,
  }) {
    return TrailState(
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      jalur: jalur ?? this.jalur,
      gunung: gunung ?? this.gunung,
      errorMessage: errorMessage ?? this.errorMessage,
      dss: dss ?? this.dss,
    );
  }

  @override
  List<Object?> get props =>
      [error, isLoading, jalur, gunung, errorMessage, dss];
}
