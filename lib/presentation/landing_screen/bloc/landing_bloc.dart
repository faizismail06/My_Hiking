import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/landing_model.dart';
part 'landing_event.dart';
part 'landing_state.dart';

/// A bloc that manages the state of a Landing according to the event that is dispatched to it.
class LandingBloc extends Bloc<LandingEvent, LandingState> {
  LandingBloc(super.initialState) {
    on<LandingInitialEvent>(_onInitialize);
  }

  Future<void> _onInitialize(
    LandingInitialEvent event,
    Emitter<LandingState> emit,
  ) async {
    // Implementation of the initialization logic goes here
  }
}
