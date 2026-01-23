part of 'pop_up_data_diri_lengkap_bloc.dart';

/// Represents the state of PopUpDataDiriLengkap in the application.

class PopUpDataDiriLengkapState extends Equatable {
  PopUpDataDiriLengkapState(this.popUpDataDiriLengkapModelObj);

  PopUpDataDiriLengkapModel? popUpDataDiriLengkapModelObj;

  @override
  List<Object?> get props => [popUpDataDiriLengkapModelObj];

  PopUpDataDiriLengkapState copyWith({
    PopUpDataDiriLengkapModel? popUpDataDiriLengkapModelObj,
  }) {
    return PopUpDataDiriLengkapState(
      popUpDataDiriLengkapModelObj ?? this.popUpDataDiriLengkapModelObj,
    );
  }
}