part of 'pop_up_lengkapi_data_diri_bloc.dart';

/// Represents the state of PopUpLengkapiDataDiri in the application.
/// ignore_for_file: must_be_immutable

class PopUpLengkapiDataDiriState extends Equatable {
  PopUpLengkapiDataDiriState(this.popUpLengkapiDataDiriModelObj);

  PopUpLengkapiDataDiriModel? popUpLengkapiDataDiriModelObj;

  @override
  List<Object?> get props => [popUpLengkapiDataDiriModelObj];

  PopUpLengkapiDataDiriState copyWith({
    PopUpLengkapiDataDiriModel? popUpLengkapiDataDiriModelObj,
  }) {
    return PopUpLengkapiDataDiriState(
      popUpLengkapiDataDiriModelObj ?? this.popUpLengkapiDataDiriModelObj,
    );
  }
}
