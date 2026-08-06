import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_export.dart';
import '../models/home_initial_model.dart';
import '../models/home_model.dart';
import '../models/homelist_item_model.dart';
import '../models/recommendation_model.dart';

part 'home_event.dart';
part 'home_state.dart';

/// A bloc that manages the state of a Home according to the event that is dispatched to it.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService _apiService = ApiService();

  HomeBloc(HomeState initialState) : super(initialState) {
    on<HomeInitialEvent>(_onInitialize);
    on<HomeRefreshEvent>(_onRefresh);
    on<HomeSearchEvent>(_onSearch);
    on<HomeFilterProvinceEvent>(_onFilterProvince);
    on<HomeFetchWithWeightsEvent>(_onFetchWithWeights);
  }

  Future<void> _onInitialize(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    await _loadHomeData(emit, useCache: true);
  }

  Future<void> _onRefresh(
    HomeRefreshEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _loadHomeData(emit, useCache: false);
    } finally {
      if (!(event.completer?.isCompleted ?? true)) {
        event.completer?.complete();
      }
    }
  }

  Future<void> _loadHomeData(
    Emitter<HomeState> emit, {
    required bool useCache,
  }) async {
    final hasCompletedExperience = await _hasCompletedExperienceOnboarding();

    emit(state.copyWith(
      searchController: TextEditingController(),
      isLoadingRecommended: hasCompletedExperience,
      hasCompletedExperience: hasCompletedExperience,
      clearRecommendationError: true,
    ));

    HomeFeedResult? cachedFeed;

    if (useCache) {
      try {
        final cachedPayload = await _apiService.getCachedHomeFeed();
        if (cachedPayload != null) {
          cachedFeed = _parseHomeFeed(cachedPayload);
          emit(_buildStateWithFeed(
            cachedFeed,
            hasCompletedExperience ? state.recommendations : const [],
            hasCompletedExperience: hasCompletedExperience,
            isLoadingRecommended: hasCompletedExperience,
          ));
        }
      } catch (e) {
        print('Error reading cached home feed: $e');
      }
    }

    HomeFeedResult? currentFeed = cachedFeed;

    try {
      final freshPayload = await _apiService.fetchHomeFeedFromServer();
      await _apiService.cacheHomeFeed(freshPayload);
      currentFeed = _parseHomeFeed(freshPayload);
    } catch (e) {
      if (currentFeed == null) {
        print('Error fetching data: $e');
        emit(state.copyWith(
          isLoadingRecommended: false,
          hasCompletedExperience: hasCompletedExperience,
          recommendationError: 'Gagal memuat data home.',
        ));
        return;
      } else {
        emit(state.copyWith(
          isLoadingRecommended: false,
          hasCompletedExperience: hasCompletedExperience,
        ));
      }
    }

    List<RecommendationModel> topRecommendations =
        hasCompletedExperience ? state.baseRecommendations : const [];
    String? recommendationError;

    if (hasCompletedExperience) {
      try {
        // Retrieve persisted DSS preferences so that recommendation uses user settings
        // instead of falling back to default equal weights.
        final prefs = await SharedPreferences.getInstance();
        final customWeights = <String, double>{};
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith('dss_pref_')) {
            final val = prefs.getDouble(key);
            if (val != null) {
              final backendKey = key.replaceFirst('dss_pref_', '');
              customWeights[backendKey] = val;
            }
          }
        }

        topRecommendations = await _apiService.fetchRecommendations(
          limit: 30,
          weights: customWeights,
        );
        topRecommendations = _sortAndRankRecommendations(topRecommendations);

        print('=== DSS INITIAL RECOMMENDATIONS RANKING ===');
        for (var i = 0; i < topRecommendations.length && i < 5; i++) {
          print('#${topRecommendations[i].rank}: ${topRecommendations[i].routeName} (Gunung ${topRecommendations[i].mountainName}) - Score: ${topRecommendations[i].score}');
        }
      } catch (e) {
        recommendationError = 'Gagal memuat rekomendasi TOPSIS.';
        print('Error fetching recommendations: $e');
      }
    }

    emit(_buildStateWithFeed(
      currentFeed,
      topRecommendations,
      hasCompletedExperience: hasCompletedExperience,
      recommendationError: recommendationError,
    ));
  }

  Future<bool> _hasCompletedExperienceOnboarding() async {
    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await _apiService.getOnboardingExperienceStatus(token);
      final rawData = response['data'];
      final data = rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{};

      final rawCompleted = data['experience_completed'];
      if (rawCompleted is bool) {
        return rawCompleted;
      }

      return rawCompleted?.toString().toLowerCase() == 'true';
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Handles the user returning from DssPreferenceScreen with custom weights.
  /// Re-fetches recommendations using the supplied weights without reloading
  /// the home feed (mountains / hero data stays intact).
  Future<void> _onFetchWithWeights(
    HomeFetchWithWeightsEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.hasCompletedExperience) return;

    // Show loading spinner inside the recommendation section only.
    emit(state.copyWith(
      isLoadingRecommended: true,
      clearRecommendationError: true,
    ));

    try {
      var results = await _apiService.fetchRecommendations(
        limit: 30,
        weights: event.weights,
      );
      results = _sortAndRankRecommendations(results);

      emit(state.copyWith(
        recommendations: results,
        baseRecommendations: results,
        isLoadingRecommended: false,
      ));
    } catch (e) {
      print('Error fetching weighted recommendations: $e');
      emit(state.copyWith(
        isLoadingRecommended: false,
        recommendationError: 'Gagal memuat rekomendasi. Coba lagi.',
      ));
    }
  }

  Future<void> _onSearch(
    HomeSearchEvent event,
    Emitter<HomeState> emit,
  ) async {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(state.copyWith(
        recommendedMountain: state.baseRecommendedMountain,
        homeInitialModelObj: state.homeInitialModelObj?.copyWith(
          homelistItemList: state.allMountains,
        ),
      ));
    } else {
      final filteredList = state.allMountains
          .where(
              (item) => item.namaGunung?.toLowerCase().contains(query) ?? false)
          .toList();

      final baseRecommended = state.baseRecommendedMountain;
      final showRecommended = baseRecommended != null &&
          (baseRecommended.namaGunung?.toLowerCase().contains(query) ?? false);

      emit(state.copyWith(
        recommendedMountain: showRecommended ? baseRecommended : null,
        clearRecommendedMountain: !showRecommended,
        homeInitialModelObj: state.homeInitialModelObj?.copyWith(
          homelistItemList: filteredList,
        ),
      ));
    }
  }

  Future<void> _onFilterProvince(
    HomeFilterProvinceEvent event,
    Emitter<HomeState> emit,
  ) async {
    final selectedProvince = event.province;

    List<HomelistItemModel> filteredByProvince;
    HomelistItemModel? filteredRecommended;

    if (selectedProvince == null) {
      // Show all mountains
      filteredByProvince = state.baseAllMountains;
      filteredRecommended = state.baseRecommendedMountain;
    } else {
      // Filter by province
      filteredByProvince = state.baseAllMountains
          .where((item) => item.province?.name == selectedProvince)
          .toList();

      // Also filter recommended if exists
      filteredRecommended = state.baseRecommendedMountain != null &&
              state.baseRecommendedMountain!.province?.name == selectedProvince
          ? state.baseRecommendedMountain
          : null;
    }

    emit(state.copyWith(
      selectedProvince: selectedProvince,
      recommendedMountain: filteredRecommended,
      allMountains: filteredByProvince,
      clearRecommendedMountain:
          filteredRecommended == null && state.baseRecommendedMountain != null,
      homeInitialModelObj: state.homeInitialModelObj?.copyWith(
        homelistItemList: filteredByProvince,
      ),
    ));
  }

  HomeFeedResult _parseHomeFeed(Map<String, dynamic> jsonData) {
    final rawRecommended = jsonData['recommended'];
    final recommended = rawRecommended is Map<String, dynamic>
        ? HomelistItemModel.fromJson(rawRecommended)
        : rawRecommended is Map
            ? HomelistItemModel.fromJson(
                Map<String, dynamic>.from(rawRecommended),
              )
            : null;
    final rawMountains = jsonData['mountains'];

    final List<dynamic> mountainItems = rawMountains is List
        ? rawMountains
        : rawMountains is Map
            ? rawMountains.values.toList()
            : const [];

    final mountains = mountainItems
        .whereType<Map>()
        .map((item) =>
            HomelistItemModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return HomeFeedResult(recommended: recommended, mountains: mountains);
  }

  HomeState _buildStateWithFeed(
    HomeFeedResult feed,
    List<RecommendationModel> recommendations, {
    required bool hasCompletedExperience,
    String? recommendationError,
    bool isLoadingRecommended = false,
  }) {
    return state.copyWith(
      recommendedMountain: feed.recommended,
      baseRecommendedMountain: feed.recommended,
      recommendations: recommendations,
      baseRecommendations: recommendations,
      recommendationError: recommendationError,
      allMountains: feed.mountains,
      baseAllMountains: feed.mountains,
      selectedProvince: null,
      isLoadingRecommended: isLoadingRecommended,
      hasCompletedExperience: hasCompletedExperience,
      homeInitialModelObj: state.homeInitialModelObj?.copyWith(
        homelistItemList: feed.mountains,
      ),
    );
  }

  List<RecommendationModel> _sortAndRankRecommendations(
    List<RecommendationModel> items,
  ) {
    final sorted = [...items]..sort((a, b) => b.score.compareTo(a.score));

    return sorted.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return item.copyWith(rank: index + 1);
    }).toList();
  }

  int _riskPriority(String risk) {
    final value = risk.toUpperCase().trim();
    if (value == 'SAFE' || value == 'LOW') {
      return 1;
    }
    if (value == 'MEDIUM' || value == 'CAUTION') {
      return 2;
    }
    return 3;
  }
}

class HomeFeedResult {
  final HomelistItemModel? recommended;
  final List<HomelistItemModel> mountains;

  HomeFeedResult({
    required this.recommended,
    required this.mountains,
  });
}
