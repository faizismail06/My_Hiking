import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/pop_up_pw_diganti_model.dart';
part 'pop_up_pw_diganti_event.dart';
part 'pop_up_pw_diganti_state.dart';

/// A bloc that manages the state of a PopUpPwDiganti according to the event that
class PopUpPwDigantiBloc
    extends Bloc<PopUpPwDigantiEvent, PopUpPwDigantiState> {
  PopUpPwDigantiBloc(super.initialState) {
    on<PopUpPwDigantiInitialEvent>(_onInitialize);
  }

  _onInitialize(
    PopUpPwDigantiInitialEvent event,
    Emitter<PopUpPwDigantiState> emit,
  ) async {}
}