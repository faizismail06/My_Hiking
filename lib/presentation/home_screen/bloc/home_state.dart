part of 'home_bloc.dart';

/// Represents the state of Home in the application.
// ignore_for_file: must_be_immutable
class HomeState extends Equatable {
  HomeState({
    this.searchController,
    this.homeInitialModelObj,
    this.homeModelObj,
    this.recommendedMountain,
    this.baseRecommendedMountain,
    this.allMountains = const [],
    this.errorMessage,
    this.selectedProvince,
    this.baseAllMountains = const [],
    this.isLoadingRecommended = false,
  });

  TextEditingController? searchController;
  HomeModel? homeModelObj;
  HomeInitialModel? homeInitialModelObj;
  HomelistItemModel? recommendedMountain;
  HomelistItemModel? baseRecommendedMountain;
  List<HomelistItemModel> allMountains;
  List<HomelistItemModel> baseAllMountains;
  String? errorMessage;
  String? selectedProvince;
  bool isLoadingRecommended;

  @override
  List<Object?> get props => [
        searchController,
        homeInitialModelObj,
        homeModelObj,
        recommendedMountain,
        baseRecommendedMountain,
        allMountains,
        baseAllMountains,
        errorMessage,
        selectedProvince,
        isLoadingRecommended,
      ];

  HomeState copyWith({
    TextEditingController? searchController,
    HomeInitialModel? homeInitialModelObj,
    HomeModel? homeModelObj,
    HomelistItemModel? recommendedMountain,
    HomelistItemModel? baseRecommendedMountain,
    List<HomelistItemModel>? allMountains,
    List<HomelistItemModel>? baseAllMountains,
    bool clearRecommendedMountain = false,
    bool clearBaseRecommendedMountain = false,
    String? errorMessage,
    String? selectedProvince,
    bool? isLoadingRecommended,
  }) {
    return HomeState(
      searchController: searchController ?? this.searchController,
      homeInitialModelObj: homeInitialModelObj ?? this.homeInitialModelObj,
      homeModelObj: homeModelObj ?? this.homeModelObj,
      recommendedMountain: clearRecommendedMountain
          ? null
          : (recommendedMountain ?? this.recommendedMountain),
      baseRecommendedMountain: clearBaseRecommendedMountain
          ? null
          : (baseRecommendedMountain ?? this.baseRecommendedMountain),
      allMountains: allMountains ?? this.allMountains,
      baseAllMountains: baseAllMountains ?? this.baseAllMountains,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
    );
  }
}
