import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';

part 'ticket_event.dart';
part 'ticket_state.dart';

/// A bloc that manages the state of a Ticket according to the event that is dispatched to it.

/// Bloc yang mengelola state Ticket berdasarkan event yang dipancarkan.
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  TicketBloc() : super(TicketInitialState()) {
    on<TicketInitialEvent>(_onInitialize);
    on<TicketLoadDataEvent>(_onLoadData);
    on<TicketAddAnggotaEvent>(_onAddAnggota);
  }

  Future<void> _fetchTicketData(int orderId, Emitter<TicketState> emit) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Authorization': 'Bearer your_token'},
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // API returns { "order": { ... } }
        final orderData = jsonResponse['order'];
        if (orderData == null) {
          emit(TicketErrorState(message: 'Data pesanan tidak ditemukan.'));
          return;
        }

        final ticket = TicketModel.fromJson(orderData);
        emit(TicketLoadedState(ticketModel: ticket));
      } else {
        print('error: ${response.body}');
        emit(TicketErrorState(message: 'Gagal memuat data.'));
      }
    } catch (e) {
      print('Exception: $e');
      emit(TicketErrorState(message: e.toString()));
    }
  }

  // Inisialisasi ticket
  _onInitialize(
    TicketInitialEvent event,
    Emitter<TicketState> emit,
  ) async {
    emit(TicketLoadingState());
    await _fetchTicketData(event.pesananId, emit);
  }

  // Memuat data ticket
  _onLoadData(
    TicketLoadDataEvent event,
    Emitter<TicketState> emit,
  ) async {
    emit(TicketLoadingState());
    await _fetchTicketData(event.pesananId, emit);
  }

  // Menambahkan anggota ke ticket
  _onAddAnggota(
    TicketAddAnggotaEvent event,
    Emitter<TicketState> emit,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/${event.pesananId}/add-member'),
        headers: {'Authorization': 'Bearer your_token'},
        body: jsonEncode({'anggota_ids': event.userId}),
      );

      if (response.statusCode == 200) {
        add(TicketLoadDataEvent(
            pesananId: event.pesananId)); // Memuat ulang data
      } else {
        emit(TicketErrorState(message: 'Gagal menambahkan anggota.'));
      }
    } catch (e) {
      emit(TicketErrorState(message: e.toString()));
    }
  }
}
