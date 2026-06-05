import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/reset_kirim_email_model.dart';

part 'reset_kirim_email_event.dart';
part 'reset_kirim_email_state.dart';

/// A bloc that manages the state of a ResetKirimEmail according to the event that is dispatched to it.
class ResetKirimEmailBloc
    extends Bloc<ResetKirimEmailEvent, ResetKirimEmailState> {
  ResetKirimEmailBloc(super.initialState) {
    on<ResetKirimEmailInitialEvent>(_onInitialize);
  }

  _onInitialize(
    ResetKirimEmailInitialEvent event,
    Emitter<ResetKirimEmailState> emit,
  ) async {
    emit(
      state.copyWith(
        passwordController: TextEditingController(),
      ),
    );
  }
}
