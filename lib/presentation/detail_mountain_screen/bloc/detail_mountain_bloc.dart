import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:myhiking/models/model.dart';
import '../../../core/app_export.dart';
import 'package:myhiking/api/api_service.dart';
part 'detail_mountain_event.dart';
part 'detail_mountain_state.dart';

/// A bloc that manages the state of a DetailMountain according to the event that is dispatched to it.
class DetailMountainBloc
    extends Bloc<DetailMountainEvent, DetailMountainState> {
  final ApiService apiService;

  DetailMountainBloc({required this.apiService})
      : super(const DetailMountainState()) {
    on<DetailMountainInitialEvent>(_onInitialize);
  }

  /// Fungsi untuk mengambil data dari API dan mengubah state
  Future<void> fetchRouteCentres(
      int mountainId, Emitter<DetailMountainState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mountains/$mountainId'),
        headers: {'Authorization': 'Bearer your_token'},
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          final resRouteCentres = ResRouteCentres.fromJson(jsonData);

          // Validate that we have at least a valid mountain
          if (resRouteCentres.gunung.nama.isEmpty) {
            emit(state.copyWith(
                isLoading: false,
                error: 'Mountain data is incomplete or invalid'));
            return;
          }

          emit(state.copyWith(
            isLoading: false,
            gunung: resRouteCentres.gunung,
            jalurList: resRouteCentres
                .data, // Pastikan jalur berasal dari ResRouteCentres
          ));
        } catch (parseError) {
          emit(state.copyWith(
              isLoading: false,
              error: 'Failed to parse mountain data: $parseError'));
        }
      } else {
        emit(state.copyWith(
            isLoading: false,
            error: 'Failed to fetch routes. Status: ${response.statusCode}'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch data: $e'));
    }
  }

  /// Handler untuk inisialisasi data
  Future<void> _onInitialize(
    DetailMountainInitialEvent event,
    Emitter<DetailMountainState> emit,
  ) async {
    // Panggil fetchRouteCentres untuk mendapatkan data
    await fetchRouteCentres(event.idGunung, emit);
  }
}
