part of 'sukses_bloc.dart';

/// Represents the state of Sukses in the application.
// ignore_for_file: must_be_immutable
class SuksesState extends Equatable {
  SuksesState({this.suksesModelObj});

  SuksesModel? suksesModelObj;

  @override
  List<Object?> get props => [suksesModelObj];

  SuksesState copyWith({SuksesModel? suksesModelObj}) {
    return SuksesState(
      suksesModelObj: suksesModelObj ?? this.suksesModelObj,
    );
  }
}
