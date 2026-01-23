import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/rincian_pembayaran_upload_model.dart';

part 'rincian_pembayaran_upload_event.dart';
part 'rincian_pembayaran_upload_state.dart';

/// A bloc that manages the state of RincianPembayaranUpload according to
/// the event that is dispatched to it.
class RincianPembayaranUploadBloc
    extends Bloc<RincianPembayaranUploadEvent, RincianPembayaranUploadState> {
  final ApiService apiService;

  // Constructor accepting the apiService as a parameter
  RincianPembayaranUploadBloc({required this.apiService})
      : super(RincianPembayaranUploadState.initial()) {
    on<RincianPembayaranUploadEvent>(_onInitialize);
    on<FetchRincianPembayaranUploadEvent>(_onFetchRincianPembayaranUpload);
  }

  // Initialization event handler (Can be used for setup tasks)
  Future<void> _onInitialize(
    RincianPembayaranUploadEvent event,
    Emitter<RincianPembayaranUploadState> emit,
  ) async {
    // Perform any setup or initialization tasks here if needed
  }

  // Event handler for fetching rincian pembayaran data

  Future<void> _onFetchRincianPembayaranUpload(
    FetchRincianPembayaranUploadEvent event,
    Emitter<RincianPembayaranUploadState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      // Ambil token autentikasi

      // Kirim permintaan GET ke API untuk mendapatkan rincian transaksi dan pembayaran
      final response = await http.get(
        Uri.parse('$baseUrl/transaksi/${event.transactionId}/with-payment'),
        headers: {
          'Authorization': 'Bearer YOUR TOKEN',
          'Content-Type': 'application/json',
        },
      );

      // Periksa status respons
      if (response.statusCode == 200) {
        // Parsing JSON jika respons berhasil
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Debugging: Print responnya untuk memeriksa data
        print("Respon data: $responseData");

        // Pastikan responseData memiliki data yang diinginkan
        if (responseData != null && responseData['data'] != null) {
          final rincianPembayaran =
              RincianPembayaranUploadModel.fromJson(responseData['data']);

          // Emit state dengan data yang berhasil diambil
          emit(state.copyWith(
            isLoading: false,
            rincianPembayaranUploadModelObj: rincianPembayaran,
            error: '',
          ));
        } else {
          // Jika data tidak ditemukan dalam response
          throw Exception('Data tidak ditemukan dalam response');
        }
      } else {
        // Jika status code tidak 200, lemparkan error
        throw Exception(
            'Gagal mengambil rincian pembayaran: ${response.statusCode}');
      }
    } catch (e) {
      // Tangani error dan emit state dengan pesan error
      emit(state.copyWith(
        isLoading: false,
        error: 'Gagal mengambil data: $e',
      ));

      // Debugging: Tampilkan error di console
      print('Error fetching data: $e');
    }
  }
}
