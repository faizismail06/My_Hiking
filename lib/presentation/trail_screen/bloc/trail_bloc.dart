import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:myhiking/models/model.dart';
import '../../../core/app_export.dart';
import 'package:myhiking/api/api_service.dart';

part 'trail_event.dart';
part 'trail_state.dart';

class TrailBloc extends Bloc<TrailEvent, TrailState> {
  final ApiService apiService;

  TrailBloc({required this.apiService}) : super(TrailState()) {
    on<TrailInitialEvent>(_onInitialize);
  }

  Future<void> _fetchTrailCentres(
      int trailId, int mountainId, Emitter<TrailState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await apiService.getToken();

      // API Request
      final response = await http.get(
        Uri.parse('$baseUrl/mountains/$mountainId/trails/$trailId'),
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      print('Headers: ${response.headers}');
      // Validasi Status HTTP
      if (response.statusCode == 200) {
        // Parsing JSON Response
        final jsonData = jsonDecode(response.body);
        final detailTrailCentres = ResDetailRouteCentres.fromJson(jsonData);

        // Emit State dengan Data yang Berhasil
        emit(state.copyWith(
          isLoading: false,
          jalur: detailTrailCentres.jalur,
          gunung: detailTrailCentres.gunung,
          dss: detailTrailCentres.dss,
        ));
      } else {
        // Emit State dengan Pesan Error
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch data. HTTP ${response.statusCode}',
        ));
      }
    } catch (e) {
      // Emit State dengan Pesan Error dari Exception
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Error fetching data: $e'));
    }
  }

  Future<void> _onInitialize(
      TrailInitialEvent event, Emitter<TrailState> emit) async {
    // Panggil Fungsi untuk Mendapatkan Data dari API
    await _fetchTrailCentres(event.jalurId, event.idGunung, emit);
  }
}
