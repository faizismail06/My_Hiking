import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/reset_page_two_model.dart';

part 'reset_page_two_event.dart';
part 'reset_page_two_state.dart';

/// A bloc that manages the state of a ResetPageTwo according to the event that is dispatched to it.
class ResetPageTwoBloc extends Bloc<ResetPageTwoEvent, ResetPageTwoState> {
  ResetPageTwoBloc(super.initialState) {
    on<ResetPageTwoInitialEvent>(_onInitialize);
  }

  _onInitialize(
    ResetPageTwoInitialEvent event,
    Emitter<ResetPageTwoState> emit,
  ) async {
    emit(
      state.copyWith(
        passwordController: TextEditingController(),
        passwordoneController: TextEditingController(),
      ),
    );
  }
}
