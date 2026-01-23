import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/ubahpw_model.dart';

part 'ubahpw_event.dart';
part 'ubahpw_state.dart';

/// A bloc that manages the state of a Ubahpw according to the event
/// that is dispatched to it.
class UbahpwBloc extends Bloc<UbahpwEvent, UbahpwState> {
  UbahpwBloc(super.initialState) {
    on<UbahpwInitialEvent>(_onInitialize);
  }

  _onInitialize(
    UbahpwInitialEvent event,
    Emitter<UbahpwState> emit,
  ) async {
    emit(
      state.copyWith(
        currentPasswordInputController: TextEditingController(),
        newPasswordInputController: TextEditingController(),
        confirmPasswordInputController: TextEditingController(),
      ),
    );
  }
}
