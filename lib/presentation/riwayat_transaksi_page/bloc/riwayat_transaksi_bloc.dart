import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../tiket_saya_page/models/tiket_saya_model.dart';

part 'riwayat_transaksi_event.dart';
part 'riwayat_transaksi_state.dart';

class RiwayatTransaksiBloc
    extends Bloc<RiwayatTransaksiEvent, RiwayatTransaksiState> {
  RiwayatTransaksiBloc(super.initialState) {
    on<RiwayatTransaksiInitialEvent>(_onInitialize);
    on<RiwayatTransaksiUserIdEvent>(_onUserIdReceived);
  }

  _onUserIdReceived(
    RiwayatTransaksiUserIdEvent event,
    Emitter<RiwayatTransaksiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final allHistoryOrders = await _fetchHistoryOrders(event.userId);
      final completedHikes = allHistoryOrders
          .where((item) => (item.status ?? '') == 'Selesai')
          .toList();

      emit(state.copyWith(
        userId: event.userId,
        isLoading: false,
        completedHikesList: completedHikes,
        historyOrdersList: allHistoryOrders,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data: $e',
      ));
    }
  }

  Future<List<TiketItemModel>> _fetchHistoryOrders(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders?user_id=$userId&per_page=50'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;

      final filteredData = data
          .where((item) {
            final status = (item['status'] ?? '').toString().trim().toLowerCase();
            return status == 'selesai' ||
                status == 'expired' ||
                status == 'cancel requested' ||
                status == 'cancelled';
          })
          .toList()
        ..sort((a, b) {
          final aId = int.tryParse(a['id'].toString()) ?? 0;
          final bId = int.tryParse(b['id'].toString()) ?? 0;
          return bId.compareTo(aId); // newest first
        });

      return filteredData.map((item) => TiketItemModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  _onInitialize(
    RiwayatTransaksiInitialEvent event,
    Emitter<RiwayatTransaksiState> emit,
  ) {
    emit(state.copyWith(
      completedHikesList: [],
      historyOrdersList: [],
    ));
  }
}
