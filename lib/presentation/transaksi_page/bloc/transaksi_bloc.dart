import 'package:equatable/equatable.dart';
import '../../../api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/transactionlist_item_model.dart';
import '../models/transaksi_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'transaksi_event.dart';
part 'transaksi_state.dart';

class TransaksiBloc extends Bloc<TransaksiEvent, TransaksiState> {
  TransaksiBloc(super.initialState) {
    on<TransaksiInitialEvent>(_onInitialize);
    on<TransaksiUserIdEvent>(_onUserIdReceived);
  }

  _onUserIdReceived(
    TransaksiUserIdEvent event,
    Emitter<TransaksiState> emit,
  ) async {
    try {
      String userId = event.userId;
      print("Received userId in _onUserIdReceived: $userId");

      List<TransactionModel> transactions = await fetchTransaksiList(userId);

      emit(state.copyWith(
        userId: userId,
        transaksiModelObj: state.transaksiModelObj?.copyWith(
          transactionlistItemList: transactions,
        ),
      ));
    } catch (e) {
      print("Error in _onUserIdReceived: $e");
      emit(state.copyWith());
    }
  }

  Future<List<TransactionModel>> fetchTransaksiList(String userId) async {
    try {
      print("Fetching transactions for userId: $userId");

      final response = await http.get(Uri.parse('$baseUrl/transaksi'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        print('Raw API data: $data');

        if (userId.isEmpty) {
          print('UserId is empty, returning empty list');
          return [];
        }

        final filteredData = data.where((item) {
          String pemesanId = item['pemesan'].toString();
          bool matches = pemesanId == userId;
          print(
              'Comparing pemesan: $pemesanId with userId: $userId, matches: $matches');
          return matches;
        }).toList();

        final transactions = filteredData
            .map((item) => TransactionModel.fromJson(item))
            .toList();

        print('Filtered transactions count: ${transactions.length}');
        return transactions;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching transactions: $e");
      throw e;
    }
  }

  _onInitialize(TransaksiInitialEvent event, Emitter<TransaksiState> emit) {
    emit(state.copyWith(
      transaksiModelObj: TransaksiModel(transactionlistItemList: []),
    ));
  }
}
