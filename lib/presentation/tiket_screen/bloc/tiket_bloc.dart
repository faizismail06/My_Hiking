import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import 'package:http/http.dart' as http;
import '../models/tiket_model.dart';

part 'tiket_event.dart';
part 'tiket_state.dart';

/// A bloc that manages the state of a Tiket according to the event that is dispatched to it.

/// Bloc yang mengelola state Tiket berdasarkan event yang dipancarkan.
class TiketBloc extends Bloc<TiketEvent, TiketState> {
  TiketBloc() : super(TiketInitialState()) {
    on<TiketInitialEvent>(_onInitialize);
    on<TiketLoadDataEvent>(_onLoadData);
    on<TiketAddAnggotaEvent>(_onAddAnggota);
  }

  Future<void> _fetchTiketData(int pesananId, Emitter<TiketState> emit) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pesanan/$pesananId'),
        headers: {'Authorization': 'Bearer your_token'},
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final tiket = TiketModel.fromJson(jsonResponse['pesanan']);
        emit(TiketLoadedState(tiketModel: tiket));
      } else {
        print('error');
        emit(TiketErrorState(message: 'Gagal memuat data.'));
      }
    } catch (e) {
      emit(TiketErrorState(message: e.toString()));
    }
  }

  // Inisialisasi tiket
  _onInitialize(
    TiketInitialEvent event,
    Emitter<TiketState> emit,
  ) async {
    emit(TiketLoadingState());
    await _fetchTiketData(event.pesananId, emit);
  }

  // Memuat data tiket
  _onLoadData(
    TiketLoadDataEvent event,
    Emitter<TiketState> emit,
  ) async {
    emit(TiketLoadingState());
    await _fetchTiketData(event.pesananId, emit);
  }

  // Menambahkan anggota ke tiket
  _onAddAnggota(
    TiketAddAnggotaEvent event,
    Emitter<TiketState> emit,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pesanan/${event.pesananId}/tambah-anggota'),
        headers: {'Authorization': 'Bearer your_token'},
        body: jsonEncode({'anggota_ids': event.userId}),
      );

      if (response.statusCode == 200) {
        add(TiketLoadDataEvent(
            pesananId: event.pesananId)); // Memuat ulang data
      } else {
        emit(TiketErrorState(message: 'Gagal menambahkan anggota.'));
      }
    } catch (e) {
      emit(TiketErrorState(message: e.toString()));
    }
  }
}
