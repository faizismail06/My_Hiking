import 'package:equatable/equatable.dart';
import '../../../api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/transactionlist_item_model.dart';
import '../models/transaction_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc(super.initialState) {
    on<TransactionInitialEvent>(_onInitialize);
    on<TransactionUserIdEvent>(_onUserIdReceived);
  }

  _onUserIdReceived(
    TransactionUserIdEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      String userId = event.userId;
      print("Received userId in _onUserIdReceived: $userId");

      List<TransactionItemModel> transactions = await fetchTransactionList(userId);

      emit(state.copyWith(
        userId: userId,
        transactionModelObj: state.transactionModelObj?.copyWith(
          transactionlistItemList: transactions,
        ),
      ));
    } catch (e) {
      print("Error in _onUserIdReceived: $e");
      emit(state.copyWith());
    }
  }

  Future<List<TransactionItemModel>> fetchTransactionList(String userId) async {
    try {
      print("Fetching transactions for userId: $userId");

      final response = await http.get(Uri.parse('$baseUrl/transactions'));

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
            .map((item) => TransactionItemModel.fromJson(item))
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

  _onInitialize(TransactionInitialEvent event, Emitter<TransactionState> emit) {
    emit(state.copyWith(
      transactionModelObj: TransactionModel(transactionlistItemList: []),
    ));
  }
}
