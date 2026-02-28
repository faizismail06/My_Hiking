import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recentclimbinglist_item_model.dart';
import '../models/history_model.dart';


part 'history_event.dart';
part 'history_state.dart';

/// A bloc that manages the state of a History according to the event that is dispatched to it.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(super.initialState) {
    on<HistoryInitialEvent>(_onInitialize);
    on<HistoryUserIdEvent>(_onUserIdReceived);
  }

  // Event handler untuk menerima userId dan memanggil fetchRecentClimbingList
  _onUserIdReceived(
    HistoryUserIdEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      // Dapatkan userId dari event
      String userId = event.userId;

      // Memanggil fetchRecentClimbingList dengan userId
      List<RecentclimbinglistItemModel> recentClimbingList = await fetchRecentClimbingList(userId);

      // Emit state dengan userId dan data yang diambil
      emit(
        state.copyWith(
          userId: userId,
          historyModelObj: state.historyModelObj?.copyWith(
            recentclimbinglistItemList: recentClimbingList,
          ),
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to process userId or fetch data: $e',
        ),
      );
    }
  }

  // Function untuk mengambil data dari API dengan userId
  Future<List<RecentclimbinglistItemModel>> fetchRecentClimbingList(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;

      // Filter data berdasarkan userId yang diterima
      final filteredData = data
          .where((item) => item['id_user'].toString() == userId)
          .map((item) => RecentclimbinglistItemModel.fromJson(item))
          .toList();

      return filteredData;
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Event handler untuk menginisialisasi data
  _onInitialize(
    HistoryInitialEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      // Mengambil data dari API tanpa menggunakan userId (untuk kasus inisialisasi)
      List<RecentclimbinglistItemModel> recentClimbingList = await fetchRecentClimbingList("");

      // Emit state dengan data yang diambil
      emit(
        state.copyWith(
          historyModelObj: state.historyModelObj?.copyWith(
            recentclimbinglistItemList: recentClimbingList,
          ),
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to fetch data: $e',
        ),
      );
    }
  }
}
