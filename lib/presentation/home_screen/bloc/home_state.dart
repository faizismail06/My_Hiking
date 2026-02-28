part of 'home_bloc.dart';

/// Represents the state of Home in the application.
// ignore_for_file: must_be_immutable
class HomeState extends Equatable {
  HomeState({
    this.searchController,
    this.homeInitialModelObj,
    this.homeModelObj,
    this.errorMessage, // Menambahkan errorMessage
  });

  TextEditingController? searchController;
  HomeModel? homeModelObj;
  HomeInitialModel? homeInitialModelObj;
  String? errorMessage; // Field untuk menyimpan pesan error

  @override
  List<Object?> get props => [
        searchController,
        homeInitialModelObj,
        homeModelObj,
        errorMessage,
      ];

  HomeState copyWith({
    TextEditingController? searchController,
    HomeInitialModel? homeInitialModelObj,
    HomeModel? homeModelObj,
    String? errorMessage,
  }) {
    return HomeState(
      searchController: searchController ?? this.searchController,
      homeInitialModelObj: homeInitialModelObj ?? this.homeInitialModelObj,
      homeModelObj: homeModelObj ?? this.homeModelObj,
      errorMessage: errorMessage ?? this.errorMessage, // Update copyWith
    );
  }
}
