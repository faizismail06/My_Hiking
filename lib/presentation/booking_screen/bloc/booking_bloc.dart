import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/bookingModel.dart';
import 'package:myhiking/models/trail_model.dart';
import '../../../core/app_export.dart';

part 'booking_event.dart';
part 'booking_state.dart';

/// A bloc that manages the state of a Booking according to the event that is dispatched to it.
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final ApiService apiService;

  BookingBloc({required this.apiService}) : super(BookingState()) {
    on<BookingInitialEvent>(_onInitialize);
    on<UpdateBookingDateEvent>(_onUpdateBookingDate);
    on<UpdateReturnDateEvent>(_onUpdateReturnDate);
    on<CreateBookingEvent>(_onCreateBooking); // Add the handler here
    on<FetchBookingQuotaEvent>(_onFetchBookingQuota);
    on<UpdateMemberIdField>(_onUpdateAnggotaID);
    on<UpdateSelectedMembers>(_onUpdateSelectedMembers);
    on<AddSelectedMember>(_onAddSelectedMember);
    on<RemoveSelectedMember>(_onRemoveSelectedMember);
  }

  // Method to fetch route centres
  Future<void> fetchRouteCentres(
      int mountainId, int trailId, Emitter<BookingState> emit) async {
    emit(state.copyWith(isLoading: true, error: '')); // Set loading state

    try {
      // Get the token for authentication
      String? token = await apiService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make the API call to fetch route centres
      final response = await http.get(
        Uri.parse('$baseUrl/mountains/$mountainId/trails/$trailId/booking'),
        headers: {'Authorization': 'Bearer $token'}, // Use the actual token
      );

      if (response.statusCode == 200) {
        // Handle successful response
        final responseData = jsonDecode(response.body);
        print('Response Data: $responseData');
        final detailRouteCentres = ResTrailModel.fromJson(responseData);

        // Emit state with updated data
        emit(state.copyWith(
          isLoading: false,
          trail: detailRouteCentres.trail, // TrailModel
          mountain: detailRouteCentres.trail.gunung, // Mountain data from API
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
    final nextState = state.copyWith(
      bookingDateFieldController:
          TextEditingController(text: event.formattedDate),
    );
    emit(nextState);
    await _triggerQuotaFetchIfPossible(nextState, emit);
  }

  Future<void> _onUpdateReturnDate(
      UpdateReturnDateEvent event, Emitter<BookingState> emit) async {
    final nextState = state.copyWith(
      returnDateFieldController:
          TextEditingController(text: event.formattedDate),
    );
    emit(nextState);
    await _triggerQuotaFetchIfPossible(nextState, emit);
  }

  Future<void> _onFetchBookingQuota(
      FetchBookingQuotaEvent event, Emitter<BookingState> emit) async {
    emit(state.copyWith(
      isQuotaLoading: true,
      quotaError: '',
    ));

    try {
      final response = await apiService.fetchTrailBookingAvailability(
        mountainId: event.idGunung,
        trailId: event.jalurId,
        tanggalNaik: event.tanggalNaik,
        tanggalTurun: event.tanggalTurun,
      );

      emit(state.copyWith(
        isQuotaLoading: false,
        quotaError: '',
        bookingQuotaAvailability: BookingQuotaAvailability.fromJson(
          response,
          tanggalNaik: event.tanggalNaik,
          tanggalTurun: event.tanggalTurun,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        isQuotaLoading: false,
        quotaError: e.toString(),
        bookingQuotaAvailability: null,
      ));
    }
  }

  Future<void> _onUpdateAnggotaID(
      UpdateMemberIdField event, Emitter<BookingState> emit) async {
    // Controller text already updated by TextField, no need to emit state
  }

  Future<void> _onUpdateSelectedMembers(
      UpdateSelectedMembers event, Emitter<BookingState> emit) async {
    emit(state.copyWith(selectedMembers: event.selectedMembers));
  }

  Future<void> _onAddSelectedMember(
      AddSelectedMember event, Emitter<BookingState> emit) async {
    final currentMembers =
        List<SelectedMember>.from(state.selectedMembers ?? []);

    // Check if member already exists
    if (!currentMembers.any((m) => m.id == event.member.id)) {
      currentMembers.add(event.member);
      emit(state.copyWith(selectedMembers: currentMembers));
    }
  }

  Future<void> _onRemoveSelectedMember(
      RemoveSelectedMember event, Emitter<BookingState> emit) async {
    final currentMembers =
        List<SelectedMember>.from(state.selectedMembers ?? []);
    currentMembers.removeWhere((m) => m.id == event.memberId);
    emit(state.copyWith(selectedMembers: currentMembers));
  }

  Future<void> _triggerQuotaFetchIfPossible(
    BookingState nextState,
    Emitter<BookingState> emit,
  ) async {
    final trail = nextState.trail;
    final mountain = nextState.mountain;
    final tanggalNaik = nextState.bookingDateFieldController?.text.trim();

    if (trail == null ||
        mountain == null ||
        tanggalNaik == null ||
        tanggalNaik.isEmpty) {
      emit(nextState.copyWith(
        bookingQuotaAvailability: null,
        quotaError: '',
        isQuotaLoading: false,
      ));
      return;
    }

    final tanggalTurun =
        (nextState.returnDateFieldController?.text.trim().isNotEmpty ?? false)
            ? nextState.returnDateFieldController!.text.trim()
            : tanggalNaik;

    await _onFetchBookingQuota(
      FetchBookingQuotaEvent(
        idGunung: mountain.id,
        jalurId: trail.id,
        tanggalNaik: tanggalNaik,
        tanggalTurun: tanggalTurun,
      ),
      emit,
    );
  }
}
