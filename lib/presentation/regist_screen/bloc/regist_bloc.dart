import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/regist_model.dart';

part 'regist_event.dart';
part 'regist_state.dart';

/// A bloc that manages the state of a Regist according to the event that is dispatched to it.
class RegistBloc extends Bloc<RegistEvent, RegistState> {
  RegistBloc(super.initialState) {
    on<RegistInitialEvent>(_onInitialize);
    on<TogglePassword2Visibility>(_onTogglePassword2Visibility);
    on<TogglePassword3Visibility>(_onTogglePassword3Visibility);
  }

  Future<void> _onInitialize(
    RegistInitialEvent event,
    Emitter<RegistState> emit,
  ) async {
    emit(
      state.copyWith(
        edittextoneController: TextEditingController(),
        emailtwoController: TextEditingController(),
        passwordtwoController: TextEditingController(),
        passwordthreeController: TextEditingController(),
      ),
    );
  }

  void _onTogglePassword2Visibility(
    TogglePassword2Visibility event,
    Emitter<RegistState> emit,
  ) {
    emit(state.copyWith(
        isPassword2Visible: !(state.isPassword2Visible ?? false)));
  }

  void _onTogglePassword3Visibility(
    TogglePassword3Visibility event,
    Emitter<RegistState> emit,
  ) {
    emit(state.copyWith(
        isPassword3Visible: !(state.isPassword3Visible ?? false)));
  }
}
