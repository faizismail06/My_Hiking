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
    this.recommendations = const [],
    this.baseRecommendations = const [],
    this.recommendationError,
    this.isLoadingRecommended = false,
    this.hasCompletedExperience = false,
  });

  TextEditingController? searchController;
  HomeModel? homeModelObj;
  HomeInitialModel? homeInitialModelObj;
  HomelistItemModel? recommendedMountain;
  HomelistItemModel? baseRecommendedMountain;
  List<HomelistItemModel> allMountains;
  List<HomelistItemModel> baseAllMountains;
  List<RecommendationModel> recommendations;
  List<RecommendationModel> baseRecommendations;
  String? errorMessage;
  String? recommendationError;
  String? selectedProvince;
  bool isLoadingRecommended;
  bool hasCompletedExperience;

  @override
  List<Object?> get props => [
        searchController,
        homeInitialModelObj,
        homeModelObj,
        recommendedMountain,
        baseRecommendedMountain,
        allMountains,
        baseAllMountains,
        recommendations,
        baseRecommendations,
        errorMessage,
        recommendationError,
        selectedProvince,
        isLoadingRecommended,
        hasCompletedExperience,
      ];

  HomeState copyWith({
    TextEditingController? searchController,
    HomeInitialModel? homeInitialModelObj,
    HomeModel? homeModelObj,
    HomelistItemModel? recommendedMountain,
    HomelistItemModel? baseRecommendedMountain,
    List<HomelistItemModel>? allMountains,
    List<HomelistItemModel>? baseAllMountains,
    List<RecommendationModel>? recommendations,
    List<RecommendationModel>? baseRecommendations,
    bool clearRecommendedMountain = false,
    bool clearBaseRecommendedMountain = false,
    bool clearRecommendationError = false,
    String? errorMessage,
    String? recommendationError,
    String? selectedProvince,
    bool? isLoadingRecommended,
    bool? hasCompletedExperience,
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
      recommendations: recommendations ?? this.recommendations,
      baseRecommendations: baseRecommendations ?? this.baseRecommendations,
      errorMessage: errorMessage ?? this.errorMessage,
      recommendationError: clearRecommendationError
          ? null
          : (recommendationError ?? this.recommendationError),
      selectedProvince: selectedProvince ?? this.selectedProvince,
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
      hasCompletedExperience:
          hasCompletedExperience ?? this.hasCompletedExperience,
    );
  }
}
