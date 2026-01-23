import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/pop_up_lengkapi_data_diri_model.dart';
part 'pop_up_lengkapi_data_diri_event.dart';
part 'pop_up_lengkapi_data_diri_state.dart';

/// A bloc that manages the state of a PopUpLengkapiDataDiri according to
class PopUpLengkapiDataDiriBloc
    extends Bloc<PopUpLengkapiDataDiriEvent, PopUpLengkapiDataDiriState> {
  PopUpLengkapiDataDiriBloc(super.initialState) {
    on<PopUpLengkapiDataDiriInitialEvent>(_onInitialize);
  }

  _onInitialize(
    PopUpLengkapiDataDiriInitialEvent event,
    Emitter<PopUpLengkapiDataDiriState> emit,
  ) async {}
}
