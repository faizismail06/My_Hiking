import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/bookingModel.dart';
import 'package:myhiking/models/jalurmodel.dart';
import '../../../core/app_export.dart';

part 'booking_event.dart';
part 'booking_state.dart';

/// A bloc that manages the state of a Booking according to the event that is dispatched to it.
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final ApiService apiService;

  BookingBloc({required this.apiService}) : super(BookingState()) {
    on<BookingInitialEvent>(_onInitialize);
    on<UpdateBookingDateEvent>(_onUpdateBookingDate);
    on<CreateBookingEvent>(_onCreateBooking); // Add the handler here
    on<UpdateMemberIdField>(_onUpdateAnggotaID);
  }

  // Method to fetch route centres
  Future<void> fetchRouteCentres(
      int idGunung, int jalurId, Emitter<BookingState> emit) async {
    emit(state.copyWith(isLoading: true, error: '')); // Set loading state

    try {
      // Get the token for authentication
      String? token = await apiService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make the API call to fetch route centres
      final response = await http.get(
        Uri.parse('$baseUrl/gunung/$idGunung/jalur/$jalurId/jalurbooking'),
        headers: {'Authorization': 'Bearer $token'}, // Use the actual token
      );

      if (response.statusCode == 200) {
        // Handle successful response
        final responseData = jsonDecode(response.body);
        print('Response Data: $responseData');
        final detailRouteCentres = ResJalurModel.fromJson(responseData);

        // Emit state with updated data
        emit(state.copyWith(
          isLoading: false,
          jalur: detailRouteCentres.jalur, // List<JalurModel>
          gunung: detailRouteCentres.jalur.gunung, // Gunung data from API
          error: '', // Clear previous errors
        ));
      } else {
        throw Exception(
            'Failed to fetch routes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors by updating the state with the error message
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to fetch data: $e', // Provide detailed error message
      ));
    }
  }

  Future<void> _onCreateBooking(
      CreateBookingEvent event, Emitter<BookingState> emit) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      final response = await apiService.createBooking(
        event.modelBooking.idGunung, // Ambil dari model
        event.modelBooking.jalurId,
        event.modelBooking.userId,
        event.modelBooking.tanggalNaik.toIso8601String(),
        event.modelBooking.tanggalTurun.toIso8601String(),
        event.modelBooking.totalHargaTiket, // Explicitly convert to double
      );

      if (response != null) {
        emit(state.copyWith(
          isLoading: false,
          modelBooking: response,
          isBookingSuccessful: true,
        ));
      } else {
        emit(state.copyWith(
            isLoading: false, error: 'Failed to create booking.'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Error occurred: $e'));
    }
  }

  Future<void> _onInitialize(
      BookingInitialEvent event, Emitter<BookingState> emit) async {
    await fetchRouteCentres(event.idGunung, event.jalurId, emit);
  }

  Future<void> _onUpdateBookingDate(
      UpdateBookingDateEvent event, Emitter<BookingState> emit) async {
    // Update the state with the new date in the controller
    emit(state.copyWith(
      bookingDateFieldController:
          TextEditingController(text: event.formattedDate),
    ));
  }

  Future<void> _onUpdateAnggotaID(
      UpdateMemberIdField event, Emitter<BookingState> emit) async {
    // Periksa apakah controller sudah ada
    final controller = state.memberIdFieldController;

    if (controller != null) {
      // Perbarui teks di controller yang ada
      controller.text = event.anggotaIds;

      // Emit state tanpa mengganti controller yang sudah ada
      emit(state.copyWith(memberIdFieldController: controller));
    } else {
      // Jika controller belum ada, buat baru
      emit(state.copyWith(
        memberIdFieldController: TextEditingController(text: event.anggotaIds),
      ));
    }
  }
}
