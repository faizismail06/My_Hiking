import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/data_profile_screen/models/res_user.dart';
import '../../../core/app_export.dart';
part 'data_profile_event.dart';
part 'data_profile_state.dart';

class DataProfileBloc extends Bloc<DataProfileEvent, DataProfileState> {
  final ApiService apiService;

  DataProfileBloc({required this.apiService}) : super(DataProfileState()) {
    on<DataProfileInitialEvent>(_onInitialize);
    on<SaveDataEvent>(_onSaveData);
    on<DisposeEvent>(_onDispose);
    on<DateOfBirthChangedEvent>(_onDateOfBirthChanged);
    on<FullNameChangedEvent>(_onFullNameChanged);
    on<NikChangedEvent>(_onNikChanged);
    on<PhoneNumberChangedEvent>(_onPhoneNumberChanged);
    on<EmergencyContactChangedEvent>(_onEmergencyContactChanged);
    on<AddressChangedEvent>(_onAddressChanged);
    on<EmailChangedEvent>(_onEmailChanged);
    on<FetchUserDataEvent>(_onFetchUserData);
  }
  // Fungsi untuk mengambil data pengguna dari API
  Future<void> _onFetchUserData(
      FetchUserDataEvent event, Emitter<DataProfileState> emit) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      String? token = await apiService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user-data/${event.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final ResUser resUser = resUserFromJson(response.body);

        // Debug print
        print('Raw date_of_birth: ${resUser.data.dateOfBirth}');

        // Buat controller untuk tanggal lahir
        TextEditingController dateController = TextEditingController();
        if (resUser.data.dateOfBirth != null) {
          String formattedDateOfBirth =
              DateFormat('yyyy-MM-dd').format(resUser.data.dateOfBirth!);
          dateController.text = formattedDateOfBirth;
        }

        emit(state.copyWith(
          isLoading: false,
          fullNameInputController:
              TextEditingController(text: resUser.data.name.toString()),
          nikInputController:
              TextEditingController(text: resUser.data.nik.toString()),
          phoneNumberInputController:
              TextEditingController(text: resUser.data.phone.toString()),
          emergencyContactInputController: TextEditingController(
              text: resUser.data.emergencyPhone.toString()),
          addressInputController:
              TextEditingController(text: resUser.data.address.toString()),
          emailInputController:
              TextEditingController(text: resUser.data.email.toString()),
          dateOfBirthController: dateController,
          error: '',
        ));
      } else {
        throw Exception(
            'Gagal mengambil data pengguna. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detail: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Gagal mengambil data: $e',
      ));
    }
  }

  Future<void> _onDateOfBirthChanged(
      DateOfBirthChangedEvent event, Emitter<DataProfileState> emit) async {
    emit(state.copyWith(
      dateOfBirthController: TextEditingController(text: event.dateOfBirth),
    ));
  }

  Future<void> _onFullNameChanged(
      FullNameChangedEvent event, Emitter<DataProfileState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  Future<void> _onNikChanged(
      NikChangedEvent event, Emitter<DataProfileState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  Future<void> _onPhoneNumberChanged(
      PhoneNumberChangedEvent event, Emitter<DataProfileState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  Future<void> _onEmergencyContactChanged(EmergencyContactChangedEvent event,
      Emitter<DataProfileState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  Future<void> _onAddressChanged(
      AddressChangedEvent event, Emitter<DataProfileState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  Future<void> _onEmailChanged(
      EmailChangedEvent event, Emitter<DataProfileState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  void _onSaveData(SaveDataEvent event, Emitter<DataProfileState> emit) {
    // Logika penyimpanan data
    final fullName = state.fullNameInputController?.text ?? '';
    final nik = state.nikInputController?.text ?? '';
    final phoneNumber = state.phoneNumberInputController?.text ?? '';
    final emergencyContact = state.emergencyContactInputController?.text ?? '';
    final address = state.addressInputController?.text ?? '';
    final email = state.emailInputController?.text ?? '';

    print('Data berhasil disimpan:');
    print('Full Name: $fullName');
    print('NIK: $nik');
    print('Phone Number: $phoneNumber');
    print('Emergency Contact: $emergencyContact');
    print('Address: $address');
    print('Email: $email');

    // Emit state jika perlu menampilkan notifikasi atau mengubah UI
    emit(state.copyWith());
  }

  void _onDispose(DisposeEvent event, Emitter<DataProfileState> emit) {
    state.fullNameInputController?.dispose();
    state.nikInputController?.dispose();
    state.phoneNumberInputController?.dispose();
    state.emergencyContactInputController?.dispose();
    state.addressInputController?.dispose();
    state.emailInputController?.dispose();
  }

  void _onInitialize(
      DataProfileInitialEvent event, Emitter<DataProfileState> emit) {
    if (state.fullNameInputController == null) {
      emit(
        state.copyWith(
          fullNameInputController: TextEditingController(),
          nikInputController: TextEditingController(),
          phoneNumberInputController: TextEditingController(),
          emergencyContactInputController: TextEditingController(),
          addressInputController: TextEditingController(),
          emailInputController: TextEditingController(),
        ),
      );
    }
  }
}
