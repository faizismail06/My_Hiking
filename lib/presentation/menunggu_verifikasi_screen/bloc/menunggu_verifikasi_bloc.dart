import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:myhiking/api/api_service.dart';
import 'dart:convert';
import '../../../core/app_export.dart';
import '../models/menunggu_verifikasi_model.dart';
part 'menunggu_verifikasi_event.dart';
part 'menunggu_verifikasi_state.dart';

/// A bloc that manages the state of a MenungguVerifikasi according to
/// the event that is dispatched to it.
class MenungguVerifikasiBloc
    extends Bloc<MenungguVerifikasiEvent, MenungguVerifikasiState> {
  final ApiService apiService;

  // Dependency injection melalui constructor
  MenungguVerifikasiBloc({required this.apiService})
      : super(MenungguVerifikasiState()) {
    on<FetchMenungguVerifikasiData>(_onFetchMenungguVerifikasiData);
  }

  Future<void> _onFetchMenungguVerifikasiData(
    FetchMenungguVerifikasiData event,
    Emitter<MenungguVerifikasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null)); // Reset error state
    try {
      final url = Uri.parse('$baseUrl/pesanan/${event.pesananId}/detailPesanan');
      print("Mengambil data untuk pesanan ID: ${event.pesananId}");

      // Lakukan permintaan GET ke API
      final response = await http.get(url);

      // Mengecek status code dari response
      if (response.statusCode == 200) {
        print(
            "Berhasil mengambil respon dari API dengan status code ${response.statusCode}");

        final jsonResponse = json.decode(response.body);
        print("Response Data: ${jsonResponse}");

        // Mengecek apakah 'success' bernilai true
        if (jsonResponse['success'] == true) {
          // Parsing data ke model MenungguVerifikasiModel
          final model = MenungguVerifikasiModel.fromJson(jsonResponse['data']);

          // Emit state dengan data yang berhasil diambil
          emit(state.copyWith(
            menungguVerifikasiModelObj: model,
            isLoading: false,
          ));

          // Cetak data model yang berhasil diparse
          print("Detail Pesanan: ${model.toString()}");
        } else {
          // Emit state dengan error jika success false
          emit(state.copyWith(
            error: jsonResponse['message'] ?? 'Gagal mengambil data',
            isLoading: false,
          ));
        }
      } else {
        // Emit state dengan error jika status code tidak 200
        emit(state.copyWith(
          error: 'Failed with status code ${response.statusCode}',
          isLoading: false,
        ));
        print("Error: Gagal dengan status code ${response.statusCode}");
      }
    } catch (e) {
      // Emit state dengan error jika terjadi pengecualian
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
      print("Error terjadi: $e");
    }
  }
}
