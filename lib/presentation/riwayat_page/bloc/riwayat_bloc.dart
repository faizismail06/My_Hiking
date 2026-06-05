import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recentclimbinglist_item_model.dart';
import '../models/riwayat_model.dart';

part 'riwayat_event.dart';
part 'riwayat_state.dart';

/// A bloc that manages the state of a Riwayat according to the event that is dispatched to it.
class RiwayatBloc extends Bloc<RiwayatEvent, RiwayatState> {
  RiwayatBloc(super.initialState) {
    on<RiwayatInitialEvent>(_onInitialize);
    on<RiwayatUserIdEvent>(_onUserIdReceived);
  }

  // Event handler untuk menerima userId dan memanggil fetchRecentClimbingList
  _onUserIdReceived(
    RiwayatUserIdEvent event,
    Emitter<RiwayatState> emit,
  ) async {
    try {
      // Dapatkan userId dari event
      String userId = event.userId;

      // Memanggil fetchRecentClimbingList dengan userId
      List<RecentclimbinglistItemModel> recentClimbingList =
          await fetchRecentClimbingList(userId);

      // Emit state dengan userId dan data yang diambil
      emit(
        state.copyWith(
          userId: userId,
          riwayatModelObj: state.riwayatModelObj?.copyWith(
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
  Future<List<RecentclimbinglistItemModel>> fetchRecentClimbingList(
      String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/pesanan'));

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
    RiwayatInitialEvent event,
    Emitter<RiwayatState> emit,
  ) async {
    try {
      // Mengambil data dari API tanpa menggunakan userId (untuk kasus inisialisasi)
      List<RecentclimbinglistItemModel> recentClimbingList =
          await fetchRecentClimbingList("");

      // Emit state dengan data yang diambil
      emit(
        state.copyWith(
          riwayatModelObj: state.riwayatModelObj?.copyWith(
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
