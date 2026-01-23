import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/pop_up_data_diri_lengkap_model.dart';
part 'pop_up_data_diri_lengkap_event.dart';
part 'pop_up_data_diri_lengkap_state.dart';

/// A bloc that manages the state of a PopUpDataDiriLengkap according to the event
class PopUpDataDiriLengkapBloc extends Bloc<PopUpDataDiriLengkapEvent, PopUpDataDiriLengkapState> {
  PopUpDataDiriLengkapBloc(super.initialState) {
    on<PopUpDataDiriLengkapInitialEvent>(_onInitialize);
  }

  _onInitialize(
    PopUpDataDiriLengkapInitialEvent event,
    Emitter<PopUpDataDiriLengkapState> emit,
  ) async {
    // Implementasi logika saat event `PopUpDataDiriLengkapInitialEvent` terjadi
  }
}