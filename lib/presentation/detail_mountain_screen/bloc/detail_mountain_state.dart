part of 'detail_mountain_bloc.dart';

/// Representasi state dari DetailMountain
class DetailMountainState extends Equatable {
  final String? error; // Untuk menyimpan pesan error
  final bool isLoading; // Untuk menandai apakah sedang memuat data
  final List<Jalur>? jalurList; // Daftar jalur pendakian
  final Gunung? gunung; // Detail gunung yang terkait

  const DetailMountainState({
    this.error,
    this.isLoading = false,
    this.jalurList,
    this.gunung,
  });

  /// Membuat salinan state dengan perubahan tertentu
  DetailMountainState copyWith({
    String? error,
    bool? isLoading,
    List<Jalur>? jalurList,
    Gunung? gunung,
  }) {
    return DetailMountainState(
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      jalurList: jalurList ?? this.jalurList,
      gunung: gunung ?? this.gunung,
    );
  }

  @override
  List<Object?> get props => [error, isLoading, jalurList, gunung];
}
