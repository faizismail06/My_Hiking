import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../api/api_service.dart';
import '../models/paymentmethodslist_item_model.dart';
import '../models/pilihan_bank_pembayaran_model.dart';

part 'pilihan_bank_pembayaran_event.dart';
part 'pilihan_bank_pembayaran_state.dart';

class PilihanBankPembayaranBloc
    extends Bloc<PilihanBankPembayaranEvent, PilihanBankPembayaranState> {
  final String apiUrl = "$baseUrl/payments";

  PilihanBankPembayaranBloc()
      : super(PilihanBankPembayaranState(
          pilihanBankPembayaranModelObj: PilihanBankPembayaranModel(
            paymentmethodslistItemList: [],
          ),
        )) {
    // Handler untuk event initial
    on<PilihanBankPembayaranInitialEvent>((event, emit) {
      emit(state);
    });

    // Handler untuk fetch data payments
    on<FetchPaymentsEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null));
      try {
        // Lakukan request ke API
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            // Parsing data
            final List<PaymentmethodslistItemModel> payments =
                (responseData['data'] as List)
                    .map((item) => PaymentmethodslistItemModel(
                          namaPayment: item['nama_pembayaran'],
                          gambarPayment: item['gambar_pembayaran'],
                          id: item['id'], // Pastikan 'id' diisi dengan benar
                        ))
                    .toList();

            // Update state dengan data baru
            final updatedModel = state.pilihanBankPembayaranModelObj?.copyWith(
              paymentmethodslistItemList: payments,
            );

            emit(state.copyWith(
              pilihanBankPembayaranModelObj: updatedModel,
              isLoading: false,
            ));
          } else {
            emit(state.copyWith(
              isLoading: false,
              error: "Gagal memuat data payments.",
            ));
          }
        } else {
          emit(state.copyWith(
            isLoading: false,
            error: "Error: ${response.statusCode}",
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          error: e.toString(),
        ));
      }
    });
  }
}
