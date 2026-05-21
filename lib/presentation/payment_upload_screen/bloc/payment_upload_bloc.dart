import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/payment_upload_model.dart';

part 'payment_upload_event.dart';
part 'payment_upload_state.dart';

/// A bloc that manages the state of PaymentUpload according to
/// the event that is dispatched to it.
class PaymentUploadBloc extends Bloc<PaymentUploadEvent, PaymentUploadState> {
  final ApiService apiService;

  // Constructor accepting the apiService as a parameter
  PaymentUploadBloc({required this.apiService})
      : super(PaymentUploadState.initial()) {
    on<PaymentUploadEvent>(_onInitialize);
    on<FetchPaymentUploadEvent>(_onFetchPaymentUpload);
  }

  // Initialization event handler (Can be used for setup tasks)
  Future<void> _onInitialize(
    PaymentUploadEvent event,
    Emitter<PaymentUploadState> emit,
  ) async {
    // Perform any setup or initialization tasks here if needed
  }

  // Event handler for fetching payment upload data

  Future<void> _onFetchPaymentUpload(
    FetchPaymentUploadEvent event,
    Emitter<PaymentUploadState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      // Ambil token autentikasi

      // Kirim permintaan GET ke API untuk mendapatkan rincian transaksi dan pembayaran
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/${event.transactionId}/with-payment'),
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
          final paymentUpload =
              PaymentUploadModel.fromJson(responseData['data']);

          // Emit state dengan data yang berhasil diambil
          emit(state.copyWith(
            isLoading: false,
            paymentUploadModelObj: paymentUpload,
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
