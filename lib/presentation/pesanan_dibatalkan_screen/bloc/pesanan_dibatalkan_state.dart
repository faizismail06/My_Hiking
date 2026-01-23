part of 'pesanan_dibatalkan_bloc.dart';

/// Represents the state of PesananDibatalkan in the application.
// ignore_for_file: must_be_immutable
class PesananDibatalkanState extends Equatable {
  PesananDibatalkanState({this.pesananDibatalkanModelObj});

  PesananDibatalkanModel? pesananDibatalkanModelObj;

  @override
  List<Object?> get props => [pesananDibatalkanModelObj];

  PesananDibatalkanState copyWith({PesananDibatalkanModel? pesananDibatalkanModelObj}) {
    return PesananDibatalkanState(
      pesananDibatalkanModelObj: pesananDibatalkanModelObj ?? this.pesananDibatalkanModelObj,
    );
  }
}
