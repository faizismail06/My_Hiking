import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/sukses_model.dart';

part 'sukses_event.dart';
part 'sukses_state.dart';

/// A bloc that manages the state of a Sukses according to the event that is dispatched to it.
class SuksesBloc extends Bloc<SuksesEvent, SuksesState> {
  SuksesBloc(super.initialState) {
    on<SuksesInitialEvent>(_onInitialize);
  }

  _onInitialize(
    SuksesInitialEvent event,
    Emitter<SuksesState> emit,
  ) async {}
}
