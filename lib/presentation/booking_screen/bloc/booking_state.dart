part of 'booking_bloc.dart';

/// Represents the state of Booking in the application.
class BookingState extends Equatable {
  // Field controllers
  final TextEditingController? bookingDateFieldController;
  final TextEditingController? memberIdFieldController;
  final TextEditingController? memberNameFieldController;

  // Data models
  final JalurModel? jalur;
  final Gunung? gunung;
  final ModelBooking? modelBooking;

  // Loading & Error state
  final bool isLoading;
  final String error;

  // Flag to indicate booking success
  final bool isBookingSuccessful;

  BookingState({
    this.bookingDateFieldController,
    this.memberIdFieldController,
    this.memberNameFieldController,
    this.jalur,
    this.gunung,
    this.modelBooking,
    this.isLoading = false,
    this.error = '',
    this.isBookingSuccessful = false,
  });

  @override
  List<Object?> get props => [
        bookingDateFieldController,
        memberIdFieldController,
        memberNameFieldController,
        jalur,
        gunung,
        modelBooking,
        isLoading,
        error,
        isBookingSuccessful,
      ];

  BookingState copyWith({
    TextEditingController? bookingDateFieldController,
    TextEditingController? memberIdFieldController,
    JalurModel? jalur,
    Gunung? gunung,
    ModelBooking? modelBooking,
    bool? isLoading,
    String? error,
    bool? isBookingSuccessful,
  }) {
    return BookingState(
      bookingDateFieldController:
          bookingDateFieldController ?? this.bookingDateFieldController,
      memberIdFieldController:
          memberIdFieldController ?? this.memberIdFieldController,
      memberNameFieldController:
          memberNameFieldController ?? this.memberNameFieldController,
      jalur: jalur ?? this.jalur,
      gunung: gunung ?? this.gunung,
      modelBooking: modelBooking ?? this.modelBooking,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isBookingSuccessful: isBookingSuccessful ?? this.isBookingSuccessful,
    );
  }
}
