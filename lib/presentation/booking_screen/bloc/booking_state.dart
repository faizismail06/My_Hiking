part of 'booking_bloc.dart';

/// Model for selected member
class SelectedMember {
  final int id;
  final String name;

  SelectedMember({required this.id, required this.name});
}

/// Represents the state of Booking in the application.
class BookingState extends Equatable {
  // Field controllers
  final TextEditingController? bookingDateFieldController;
  final TextEditingController? returnDateFieldController;
  final TextEditingController? memberIdFieldController;
  final TextEditingController? memberNameFieldController;

  // Data models
  final TrailModel? trail;
  final Mountain? mountain;
  final ModelBooking? modelBooking;

  // Selected members list
  final List<SelectedMember>? selectedMembers;

  // Loading & Error state
  final bool isLoading;
  final bool isQuotaLoading;
  final String error;
  final String quotaError;

  // Flag to indicate booking success
  final bool isBookingSuccessful;
  final BookingQuotaAvailability? bookingQuotaAvailability;

  const BookingState({
    this.bookingDateFieldController,
    this.returnDateFieldController,
    this.memberIdFieldController,
    this.memberNameFieldController,
    this.trail,
    this.mountain,
    this.modelBooking,
    this.selectedMembers,
    this.isLoading = false,
    this.isQuotaLoading = false,
    this.error = '',
    this.quotaError = '',
    this.isBookingSuccessful = false,
    this.bookingQuotaAvailability,
  });

  @override
  List<Object?> get props => [
        bookingDateFieldController,
        returnDateFieldController,
        memberIdFieldController,
        memberNameFieldController,
        trail,
        mountain,
        modelBooking,
        selectedMembers,
        isLoading,
        isQuotaLoading,
        error,
        quotaError,
        isBookingSuccessful,
        bookingQuotaAvailability,
      ];

  BookingState copyWith({
    TextEditingController? bookingDateFieldController,
    TextEditingController? returnDateFieldController,
    TextEditingController? memberIdFieldController,
    TextEditingController? memberNameFieldController,
    TrailModel? trail,
    Mountain? mountain,
    ModelBooking? modelBooking,
    List<SelectedMember>? selectedMembers,
    bool? isLoading,
    bool? isQuotaLoading,
    String? error,
    String? quotaError,
    bool? isBookingSuccessful,
    Object? bookingQuotaAvailability = _bookingStateNoValue,
  }) {
    return BookingState(
      bookingDateFieldController:
          bookingDateFieldController ?? this.bookingDateFieldController,
      returnDateFieldController:
          returnDateFieldController ?? this.returnDateFieldController,
      memberIdFieldController:
          memberIdFieldController ?? this.memberIdFieldController,
      memberNameFieldController:
          memberNameFieldController ?? this.memberNameFieldController,
      trail: trail ?? this.trail,
      mountain: mountain ?? this.mountain,
      modelBooking: modelBooking ?? this.modelBooking,
      selectedMembers: selectedMembers ?? this.selectedMembers,
      isLoading: isLoading ?? this.isLoading,
      isQuotaLoading: isQuotaLoading ?? this.isQuotaLoading,
      error: error ?? this.error,
      quotaError: quotaError ?? this.quotaError,
      isBookingSuccessful: isBookingSuccessful ?? this.isBookingSuccessful,
      bookingQuotaAvailability:
          identical(bookingQuotaAvailability, _bookingStateNoValue)
              ? this.bookingQuotaAvailability
              : bookingQuotaAvailability as BookingQuotaAvailability?,
    );
  }
}

const Object _bookingStateNoValue = Object();

class BookingQuotaAvailability extends Equatable {
  final int? dailyHikerLimit;
  final List<BookingQuotaDay> days;
  final String tanggalNaik;
  final String tanggalTurun;

  const BookingQuotaAvailability({
    required this.dailyHikerLimit,
    required this.days,
    required this.tanggalNaik,
    required this.tanggalTurun,
  });

  BookingQuotaDay? get startDay {
    for (final day in days) {
      if (day.date == tanggalNaik) {
        return day;
      }
    }
    return days.isNotEmpty ? days.first : null;
  }

  bool get hasFullDay => days.any((day) => day.isFull == true);

  factory BookingQuotaAvailability.fromJson(
    Map<String, dynamic> json, {
    required String tanggalNaik,
    required String tanggalTurun,
  }) {
    final trail = json['trail'] is Map
        ? Map<String, dynamic>.from(json['trail'] as Map)
        : <String, dynamic>{};
    final slotAvailability = json['slot_availability'] is Map
        ? Map<String, dynamic>.from(json['slot_availability'] as Map)
        : <String, dynamic>{};

    final rawDays = slotAvailability['days'] is List
        ? slotAvailability['days'] as List
        : const [];

    return BookingQuotaAvailability(
      dailyHikerLimit: int.tryParse(
        (trail['daily_hiker_limit'] ??
                json['daily_hiker_limit'] ??
                slotAvailability['daily_hiker_limit'])
            .toString(),
      ),
      days: rawDays
          .whereType<Map>()
          .map((item) =>
              BookingQuotaDay.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      tanggalNaik: tanggalNaik,
      tanggalTurun: tanggalTurun,
    );
  }

  @override
  List<Object?> get props => [dailyHikerLimit, days, tanggalNaik, tanggalTurun];
}

class BookingQuotaDay extends Equatable {
  final String date;
  final int? remainingSlots;
  final int? currentHikers;
  final bool isFull;

  const BookingQuotaDay({
    required this.date,
    required this.remainingSlots,
    required this.currentHikers,
    required this.isFull,
  });

  factory BookingQuotaDay.fromJson(Map<String, dynamic> json) {
    return BookingQuotaDay(
      date: (json['date'] ?? '').toString(),
      remainingSlots: json['remaining_slots'] == null
          ? null
          : int.tryParse(json['remaining_slots'].toString()),
      currentHikers: json['current_hikers'] == null
          ? null
          : int.tryParse(json['current_hikers'].toString()),
      isFull: json['is_full'] == true,
    );
  }

  @override
  List<Object?> get props => [date, remainingSlots, currentHikers, isFull];
}
