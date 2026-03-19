import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/home_initial_model.dart';
import '../models/home_model.dart';
import '../models/homelist_item_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'home_event.dart';
part 'home_state.dart';

/// A bloc that manages the state of a Home according to the event that is dispatched to it.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(HomeState initialState) : super(initialState) {
    on<HomeInitialEvent>(_onInitialize);
    on<HomeSearchEvent>(_onSearch);
  }

  Future<void> _onInitialize(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(searchController: TextEditingController()));

    try {
      final feed = await fetchHomeFeed();
      emit(state.copyWith(
        recommendedMountain: feed.recommended,
        baseRecommendedMountain: feed.recommended,
        allMountains: feed.mountains,
        homeInitialModelObj: state.homeInitialModelObj?.copyWith(
          homelistItemList: feed.mountains,
        ),
      ));
    } catch (e) {
      // Tangani kesalahan jika API tidak berhasil diambil
      print('Error fetching data: $e');
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

  Future<HomeFeedResult> fetchHomeFeed() async {
    final token = await ApiService().getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/mountains/home-feed'),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final recommended = jsonData['recommended'] is Map<String, dynamic>
          ? HomelistItemModel.fromJson(jsonData['recommended'] as Map<String, dynamic>)
          : null;
      final rawMountains = jsonData['mountains'];

      final List<dynamic> mountainItems = rawMountains is List
        ? rawMountains
        : rawMountains is Map
          ? rawMountains.values.toList()
          : const [];

      final mountains = mountainItems
        .whereType<Map>()
        .map((item) => HomelistItemModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

      return HomeFeedResult(recommended: recommended, mountains: mountains);
    } else {
      throw Exception('Failed to load data');
    }
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
