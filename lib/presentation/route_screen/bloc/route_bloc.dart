import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:myhiking/models/model.dart';
import '../../../core/app_export.dart';
import 'package:myhiking/api/api_service.dart';

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final ApiService apiService;

  RouteBloc({required this.apiService}) : super(RouteState()) {
    on<RouteInitialEvent>(_onInitialize);
  }

  Future<void> _fetchRouteCentres(
      int jalurId, int idGunung, Emitter<RouteState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      // API Request
      final response = await http.get(
        Uri.parse('$baseUrl/gunung/$idGunung/jalur/$jalurId'),
        headers: {'Authorization': 'Bearer your_token'},
      );
      print('Headers: ${response.headers}');
      // Validasi Status HTTP
      if (response.statusCode == 200) {
        // Parsing JSON Response
        final jsonData = jsonDecode(response.body);
        final detailRouteCentres = ResDetailRouteCentres.fromJson(jsonData);

        // Emit State dengan Data yang Berhasil
        emit(state.copyWith(
          isLoading: false,
          jalur: detailRouteCentres.jalur,
          gunung: detailRouteCentres.gunung,
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
      RouteInitialEvent event, Emitter<RouteState> emit) async {
    // Panggil Fungsi untuk Mendapatkan Data dari API
    await _fetchRouteCentres(event.jalurId, event.idGunung, emit);
  }
}
