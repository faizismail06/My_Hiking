part of 'beranda_bloc.dart';

/// Represents the state of Beranda in the application.
// ignore_for_file: must_be_immutable
class BerandaState extends Equatable {
  BerandaState({
    this.searchController,
    this.berandaInitialModelObj,
    this.berandaModelObj,
    this.errorMessage, // Menambahkan errorMessage
  });

  TextEditingController? searchController;
  BerandaModel? berandaModelObj;
  BerandaInitialModel? berandaInitialModelObj;
  String? errorMessage; // Field untuk menyimpan pesan error

  @override
  List<Object?> get props => [
        searchController,
        berandaInitialModelObj,
        berandaModelObj,
        errorMessage,
      ];

  BerandaState copyWith({
    TextEditingController? searchController,
    BerandaInitialModel? berandaInitialModelObj,
    BerandaModel? berandaModelObj,
    String? errorMessage,
  }) {
    return BerandaState(
      searchController: searchController ?? this.searchController,
      berandaInitialModelObj: berandaInitialModelObj ?? this.berandaInitialModelObj,
      berandaModelObj: berandaModelObj ?? this.berandaModelObj,
      errorMessage: errorMessage ?? this.errorMessage, // Update copyWith
    );
  }
}
