import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/tata_tertib_model.dart';

part 'tata_tertib_event.dart';
part 'tata_tertib_state.dart';

/// A bloc that manages the state of a TataTertib according to
/// the event that is dispatched to it.
class TataTertibBloc extends Bloc<TataTertibEvent, TataTertibState> {
  final ApiService apiService;

  TataTertibBloc({required this.apiService}) : super(TataTertibState()) {
    on<TataTertibInitialEvent>(_onInitialize);
  }

  // Fungsi untuk meng-handle inisialisasi dan pemanggilan API
  Future<void> _onInitialize(
    TataTertibInitialEvent event,
    Emitter<TataTertibState> emit,
  ) async {
    emit(state.copyWith(isLoading: true)); // Menandakan loading

    try {
      // Panggil fungsi getTataTertibByJalur untuk mendapatkan data tata tertib
      final tataTertibData = await getTataTertibByJalur(event.jalurId);

      // Emit state dengan data tata tertib yang berhasil didapatkan
      emit(state.copyWith(
        tataTertibs: tataTertibData, // Menyimpan data tata tertib
        isLoading: false, // Menandakan loading selesai
      ));
    } catch (e) {
      // Emit state dengan error jika gagal
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching tata tertib: $e', // Pesan error
      ));
    }
  }

  // Fungsi untuk mendapatkan tata tertib berdasarkan jalurId
  Future<List<TataTertibModel>> getTataTertibByJalur(int? jalurId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tata-tertib/jalur/$jalurId'),
        headers: {'Accept': 'application/json'},
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Memeriksa status kode dari response
      if (response.statusCode == 200) {
        // Mengonversi body response menjadi Map
        final Map<String, dynamic> responseMap = json.decode(response.body);

        // Debug print
        print('Response Map: $responseMap');

        // Mengambil array data dari response
        final List<dynamic> dataList = responseMap['data'] as List<dynamic>;

        // Debug print
        print('Data List: $dataList');

        // Mengonversi setiap item dalam List<dynamic> menjadi TataTertibModel
        final tataTertibs =
            dataList.map((item) => TataTertibModel.fromJson(item)).toList();

        // Debug print
        print('Converted TataTertibs: ${tataTertibs.length}');
        tataTertibs.forEach((t) => print('Description: ${t.description}'));

        return tataTertibs;
      } else {
        throw Exception('Failed to load tata tertib: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTataTertibByJalur: $e');
      throw Exception('Failed to load tata tertib: $e');
    }
  }
}
