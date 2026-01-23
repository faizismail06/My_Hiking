import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/beranda_initial_model.dart';
import '../models/beranda_model.dart';
import '../models/homelist_item_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'beranda_event.dart';
part 'beranda_state.dart';

/// A bloc that manages the state of a Beranda according to the event that is dispatched to it.
class BerandaBloc extends Bloc<BerandaEvent, BerandaState> {
  BerandaBloc(BerandaState initialState) : super(initialState) {
    on<BerandaInitialEvent>(_onInitialize);
    on<BerandaSearchEvent>(_onSearch);
  }

  Future<void> _onInitialize(
    BerandaInitialEvent event,
    Emitter<BerandaState> emit,
  ) async {
    emit(state.copyWith(searchController: TextEditingController()));

    try {
      List<HomelistItemModel> homelistItems = await fetchGunungData();
      emit(state.copyWith(
        berandaInitialModelObj: state.berandaInitialModelObj?.copyWith(
          homelistItemList: homelistItems,
        ),
      ));
    } catch (e) {
      // Tangani kesalahan jika API tidak berhasil diambil
      print('Error fetching data: $e');
    }
  }

  Future<void> _onSearch(
    BerandaSearchEvent event,
    Emitter<BerandaState> emit,
  ) async {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      // If the search query is empty, show all items again
      final homelistItems = await fetchGunungData();
      emit(state.copyWith(
        berandaInitialModelObj: state.berandaInitialModelObj?.copyWith(
          homelistItemList: homelistItems,
        ),
      ));
    } else {
      // Filter the list based on the search query
      final filteredList = state.berandaInitialModelObj?.homelistItemList
          .where((item) => item.namaGunung?.toLowerCase().contains(query) ?? false)
          .toList();
      emit(state.copyWith(
        berandaInitialModelObj: state.berandaInitialModelObj?.copyWith(
          homelistItemList: filteredList ?? [],
        ),
      ));
    }
  }

  // Fungsi untuk mengambil data gunung
  Future<List<HomelistItemModel>> fetchGunungData() async {
    final response =
        await http.get(Uri.parse('$baseUrl/gunung'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      // print(jsonData); // Menampilkan data JSON yang diterima

      return jsonData.map((data) => HomelistItemModel.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }
}
