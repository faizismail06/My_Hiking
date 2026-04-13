import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tiket_saya_model.dart';

part 'tiket_saya_event.dart';
part 'tiket_saya_state.dart';

class TiketSayaBloc extends Bloc<TiketSayaEvent, TiketSayaState> {
  TiketSayaBloc(super.initialState) {
    on<TiketSayaInitialEvent>(_onInitialize);
    on<TiketSayaUserIdEvent>(_onUserIdReceived);
  }

  _onUserIdReceived(
    TiketSayaUserIdEvent event,
    Emitter<TiketSayaState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      String userId = event.userId;

      // Fetch orders and transactions in parallel
      final results = await Future.wait([
        _fetchOrders(userId),
        _fetchTransactions(userId),
      ]);

      final allOrders = results[0] as List<TiketItemModel>;
      final transactions = results[1] as List<TransaksiItemModel>;

      // Split orders into active and completed
      final activeTickets = allOrders
          .where(
            (o) =>
                o.status != 'Selesai' &&
                o.status != 'Dibatalkan' &&
                o.status != 'Expired',
          )
          .toList();

      final completedHikes =
          allOrders.where((o) => o.status == 'Selesai').toList();

      // Build a transaction map keyed by pesanan_id for quick lookup
      final Map<int, TransaksiItemModel> txMap = {};
      for (var tx in transactions) {
        if (tx.pesananId != null) {
          txMap[tx.pesananId!] = tx;
        }
      }

      emit(state.copyWith(
        userId: userId,
        isLoading: false,
        tiketSayaModelObj: TiketSayaModel(
          activeTicketsList: activeTickets,
          completedHikesList: completedHikes,
        ),
        transactionMap: txMap,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data: $e',
      ));
    }
  }

  Future<List<TiketItemModel>> _fetchOrders(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;

      final filteredData =
          data.where((item) => item['id_user'].toString() == userId).toList()
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

  Future<List<TransaksiItemModel>> _fetchTransactions(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;

        if (userId.isEmpty) return [];

        return data
            .where((item) => item['pemesan'].toString() == userId)
            .map((item) => TransaksiItemModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      // If transactions fail, return empty list (non-critical)
      print('Warning: Failed to fetch transactions: $e');
      return [];
    }
  }

  _onInitialize(
    TiketSayaInitialEvent event,
    Emitter<TiketSayaState> emit,
  ) async {
    emit(state.copyWith(
      tiketSayaModelObj: TiketSayaModel(
        activeTicketsList: [],
        completedHikesList: [],
      ),
    ));
  }
}
