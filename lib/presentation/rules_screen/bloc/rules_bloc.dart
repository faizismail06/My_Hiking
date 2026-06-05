import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:myhiking/api/api_service.dart';
import '../../../core/app_export.dart';
import '../models/rule_model.dart';

part 'rules_event.dart';
part 'rules_state.dart';

/// A bloc that manages the state of a Rules according to
/// the event that is dispatched to it.
class RulesBloc extends Bloc<RulesEvent, RulesState> {
  final ApiService apiService;

  RulesBloc({required this.apiService}) : super(RulesState()) {
    on<RulesInitialEvent>(_onInitialize);
  }

  // Fungsi untuk meng-handle inisialisasi dan pemanggilan API
  Future<void> _onInitialize(
    RulesInitialEvent event,
    Emitter<RulesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true)); // Menandakan loading

    try {
      // Panggil fungsi getRulesByJalur untuk mendapatkan data tata tertib
      final rulesData = await getRulesByJalur(event.jalurId);

      // Emit state dengan data rules yang berhasil didapatkan
      emit(state.copyWith(
        rules: rulesData, // Menyimpan data rules
        isLoading: false, // Menandakan loading selesai
      ));
    } catch (e) {
      // Emit state dengan error jika gagal
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching rules: $e', // Pesan error
      ));
    }
  }

  // Fungsi untuk mendapatkan rules berdasarkan trailId
  Future<List<RuleModel>> getRulesByJalur(int? trailId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rules/trail/$trailId'),
        headers: {'Accept': 'application/json'},
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Memeriksa status kode dari response
      if (response.statusCode == 200) {
        // Mengonversi body response menjadi Map
        final Map<String, dynamic> responseMap = json.decode(response.body);

        // Debug print
        print('Response Map: $responseMap');

        // Mengambil array data dari response
        final List<dynamic> dataList = responseMap['data'] as List<dynamic>;

        // Debug print
        print('Data List: $dataList');

        // Mengonversi setiap item dalam List<dynamic> menjadi RuleModel
        final rules = dataList.map((item) => RuleModel.fromJson(item)).toList();

        // Debug print
        print('Converted Rules: ${rules.length}');
        rules.forEach((r) => print('Description: ${r.description}'));

        return rules;
      } else {
        throw Exception('Failed to load rules: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRulesByJalur: $e');
      throw Exception('Failed to load rules: $e');
    }
  }
}
