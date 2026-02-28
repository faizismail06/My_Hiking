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
  final String error;

  // Flag to indicate booking success
  final bool isBookingSuccessful;

  BookingState({
    this.bookingDateFieldController,
    this.memberIdFieldController,
    this.memberNameFieldController,
    this.trail,
    this.mountain,
    this.modelBooking,
    this.selectedMembers,
    this.isLoading = false,
    this.error = '',
    this.isBookingSuccessful = false,
  });

  @override
  List<Object?> get props => [
        bookingDateFieldController,
        memberIdFieldController,
        memberNameFieldController,
        trail,
        mountain,
        modelBooking,
        selectedMembers,
        isLoading,
        error,
        isBookingSuccessful,
      ];

  BookingState copyWith({
    TextEditingController? bookingDateFieldController,
    TextEditingController? memberIdFieldController,
    TrailModel? trail,
    Mountain? mountain,
    ModelBooking? modelBooking,
    List<SelectedMember>? selectedMembers,
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
      trail: trail ?? this.trail,
      mountain: mountain ?? this.mountain,
      modelBooking: modelBooking ?? this.modelBooking,
      selectedMembers: selectedMembers ?? this.selectedMembers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isBookingSuccessful: isBookingSuccessful ?? this.isBookingSuccessful,
    );
  }
}
