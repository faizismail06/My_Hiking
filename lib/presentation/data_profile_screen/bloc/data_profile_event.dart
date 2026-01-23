part of 'data_profile_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// DataProfile widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class DataProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the DataProfile widget is first created.
class DataProfileInitialEvent extends DataProfileEvent {
  @override
  List<Object?> get props => [];
}

class UpdatePasswordEvent extends DataProfileEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  UpdatePasswordEvent({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword, confirmPassword];
}

class FetchUserDataEvent extends DataProfileEvent {
  final int? userId;

  FetchUserDataEvent({this.userId});

  @override
  List<Object?> get props => [userId];
}

class SaveDataEvent extends DataProfileEvent {}

class DisposeEvent extends DataProfileEvent {}

// Full Name
class FullNameChangedEvent extends DataProfileEvent {
  final String value;

  FullNameChangedEvent(this.value);

  @override
  List<Object?> get props => [value];
}

// NIK
class NikChangedEvent extends DataProfileEvent {
  final String value;

  NikChangedEvent(this.value);

  @override
  List<Object?> get props => [value];
}

// Phone Number
class PhoneNumberChangedEvent extends DataProfileEvent {
  final String value;

  PhoneNumberChangedEvent(this.value);

  @override
  List<Object?> get props => [value];
}

// Emergency Contact
class EmergencyContactChangedEvent extends DataProfileEvent {
  final String value;

  EmergencyContactChangedEvent(this.value);

  @override
  List<Object?> get props => [value];
}

// Address
class AddressChangedEvent extends DataProfileEvent {
  final String value;

  AddressChangedEvent(this.value);

  @override
  List<Object?> get props => [value];
}

// Email
class EmailChangedEvent extends DataProfileEvent {
  final String value;

  EmailChangedEvent(this.value);

  @override
  List<Object?> get props => [value];
}

class DateOfBirthChangedEvent extends DataProfileEvent {
  final String dateOfBirth;

  DateOfBirthChangedEvent(this.dateOfBirth);

  @override
  List<Object> get props => [dateOfBirth];
}
