import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/profile_model.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// A bloc that manages the state of a Profile according to the event that is dispatched to it.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(super.initialState) {
    on<ProfileInitialEvent>(_onInitialize);
  }

  /// Handles the initialization of the ProfileBloc when [ProfileInitialEvent] is dispatched.
  Future<void> _onInitialize(
    ProfileInitialEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Add your initialization logic here.
  }
}
