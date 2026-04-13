import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/home_initial_model.dart';
import '../models/home_model.dart';
import '../models/homelist_item_model.dart';

part 'home_event.dart';
part 'home_state.dart';

/// A bloc that manages the state of a Home according to the event that is dispatched to it.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService _apiService = ApiService();

  HomeBloc(HomeState initialState) : super(initialState) {
    on<HomeInitialEvent>(_onInitialize);
    on<HomeSearchEvent>(_onSearch);
  }

  Future<void> _onInitialize(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(searchController: TextEditingController()));

    HomeFeedResult? cachedFeed;

    try {
      final cachedPayload = await _apiService.getCachedHomeFeed();
      if (cachedPayload != null) {
        cachedFeed = _parseHomeFeed(cachedPayload);
        emit(_buildStateWithFeed(cachedFeed));
      }
    } catch (e) {
      print('Error reading cached home feed: $e');
    }

    try {
      final freshPayload = await _apiService.fetchHomeFeedFromServer();
      await _apiService.cacheHomeFeed(freshPayload);
      final freshFeed = _parseHomeFeed(freshPayload);
      emit(_buildStateWithFeed(freshFeed));
    } catch (e) {
      if (cachedFeed == null) {
        print('Error fetching data: $e');
      }
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
          .where((item) => item.namaGunung?.toLowerCase().contains(query) ?? false)
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

  HomeFeedResult _parseHomeFeed(Map<String, dynamic> jsonData) {
    final recommended = jsonData['recommended'] is Map<String, dynamic>
        ? HomelistItemModel.fromJson(
            jsonData['recommended'] as Map<String, dynamic>)
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

  HomeState _buildStateWithFeed(HomeFeedResult feed) {
    return state.copyWith(
      recommendedMountain: feed.recommended,
      baseRecommendedMountain: feed.recommended,
      allMountains: feed.mountains,
      homeInitialModelObj: state.homeInitialModelObj?.copyWith(
        homelistItemList: feed.mountains,
      ),
    );
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
