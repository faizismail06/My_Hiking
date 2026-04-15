part of 'booking_bloc.dart';

/// Abstract class for all events related to Booking.
class BookingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event triggered when the Booking widget is first created.
class BookingInitialEvent extends BookingEvent {
  // final int userId;
  final int idGunung;
  final int jalurId;
  // final String tanggalNaik;
  // final String tanggalTurun;
  // final String totalHargaTiket;

  BookingInitialEvent({
    // required this.userId,
    required this.idGunung,
    required this.jalurId,
    // required this.tanggalNaik,
    // required this.tanggalTurun,
    // required this.totalHargaTiket,
  });

  @override
  List<Object?> get props => [
        // userId,
        idGunung,
        jalurId,
        // tanggalNaik,
        // tanggalTurun,
        // totalHargaTiket,
      ];
}

/// Event triggered when the user changes the booking date.
class ChangeDateEvent extends BookingEvent {
  final DateTime date;

  ChangeDateEvent({required this.date});

  @override
  List<Object?> get props => [date];
}

// Event untuk mengupdate tanggal naik
class UpdateBookingDateEvent extends BookingEvent {
  final String formattedDate;

  UpdateBookingDateEvent(this.formattedDate);

  @override
  List<Object?> get props => [formattedDate];
}

// Event untuk mengupdate tanggal turun
class UpdateReturnDateEvent extends BookingEvent {
  final String formattedDate;

  UpdateReturnDateEvent(this.formattedDate);

  @override
  List<Object?> get props => [formattedDate];
}

class CreateBookingEvent extends BookingEvent {
  final ModelBooking modelBooking;

  CreateBookingEvent(this.modelBooking);

  @override
  List<Object> get props => [modelBooking];
}

// Event untuk mengupdate memberIdFieldController
class UpdateMemberIdField extends BookingEvent {
  final String anggotaIds;

  UpdateMemberIdField(this.anggotaIds);
}

// Event to update selected members list
class UpdateSelectedMembers extends BookingEvent {
  final List<SelectedMember> selectedMembers;

  UpdateSelectedMembers(this.selectedMembers);

  @override
  List<Object?> get props => [selectedMembers];
}

// Event to add a single selected member
class AddSelectedMember extends BookingEvent {
  final SelectedMember member;

  AddSelectedMember(this.member);

  @override
  List<Object?> get props => [member];
}

// Event to remove a selected member
class RemoveSelectedMember extends BookingEvent {
  final int memberId;

  RemoveSelectedMember(this.memberId);

  @override
  List<Object?> get props => [memberId];
}


/// Event triggered when the user updates their booking details.
// class UpdateBookingEvent extends BookingEvent {
//   final int bookingId;
//   final DateTime newTanggalNaik;
//   final DateTime newTanggalTurun;
//   final double newTotalHargaTiket;

//   UpdateBookingEvent({
//     required this.bookingId,
//     required this.newTanggalNaik,
//     required this.newTanggalTurun,
//     required this.newTotalHargaTiket,
//   });

//   @override
//   List<Object?> get props => [
//         bookingId,
//         newTanggalNaik,
//         newTanggalTurun,
//         newTotalHargaTiket,
//       ];
// }

// /// Event triggered when the user cancels their booking.
// class CancelBookingEvent extends BookingEvent {
//   final int bookingId;

//   CancelBookingEvent({required this.bookingId});

//   @override
//   List<Object?> get props => [bookingId];
// }
