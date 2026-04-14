import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
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
    emit(state.copyWith(
      searchController: TextEditingController(),
      isLoadingRecommended: true,
      clearRecommendationError: true,
    ));

    HomeFeedResult? cachedFeed;

    if (useCache) {
      try {
        final cachedPayload = await _apiService.getCachedHomeFeed();
        if (cachedPayload != null) {
          cachedFeed = _parseHomeFeed(cachedPayload);
          emit(_buildStateWithFeed(cachedFeed, state.recommendations));
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
          recommendationError: 'Gagal memuat data home.',
        ));
        return;
      } else {
        emit(state.copyWith(isLoadingRecommended: false));
      }
    }

    List<RecommendationModel> topRecommendations = state.baseRecommendations;
    String? recommendationError;

    try {
      topRecommendations = await _apiService.fetchRecommendations(limit: 30);
      topRecommendations = _sortAndRankRecommendations(topRecommendations);
    } catch (e) {
      recommendationError = 'Gagal memuat rekomendasi TOPSIS.';
      print('Error fetching recommendations: $e');
    }

    emit(_buildStateWithFeed(
      currentFeed,
      topRecommendations,
      recommendationError: recommendationError,
    ));
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
    String? recommendationError,
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
      isLoadingRecommended: false,
      homeInitialModelObj: state.homeInitialModelObj?.copyWith(
        homelistItemList: feed.mountains,
      ),
    );
  }

  List<RecommendationModel> _sortAndRankRecommendations(
    List<RecommendationModel> items,
  ) {
    final sorted = [...items]..sort((a, b) => b.score.compareTo(a.score));
    final uniqueByMountain = <RecommendationModel>[];
    final seenMountains = <String>{};

    for (final item in sorted) {
      final key = item.mountainName
          .toLowerCase()
          .replaceAll('gunung', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (key.isEmpty || seenMountains.contains(key)) {
        continue;
      }

      seenMountains.add(key);
      uniqueByMountain.add(item);
    }

    return uniqueByMountain.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return item.copyWith(rank: index + 1);
    }).toList();
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
