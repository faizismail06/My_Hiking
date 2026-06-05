import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/kode_verifikasi_model.dart';
part 'kode_verifikasi_event.dart';
part 'kode_verifikasi_state.dart';

// A bloc that manages the state of a KodeVerifikasi according to the event that is dispatched
class KodeVerifikasiBloc
    extends Bloc<KodeVerifikasiEvent, KodeVerifikasiState> {
  KodeVerifikasiBloc(super.initialState) {
    on<KodeVerifikasiInitialEvent>(_onInitialize);
  }

  _onInitialize(
    KodeVerifikasiInitialEvent event,
    Emitter<KodeVerifikasiState> emit,
  ) async {
    emit(
      state.copyWith(
        passwordController: TextEditingController(),
      ),
    );
  }
}
