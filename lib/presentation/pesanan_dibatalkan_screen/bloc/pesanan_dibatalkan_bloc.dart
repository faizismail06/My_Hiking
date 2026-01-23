import 'package:equatable/equatable.dart';
import '../../../../core/app_export.dart';
import '../models/pesanan_dibatalkan_model.dart';

part 'pesanan_dibatalkan_event.dart';
part 'pesanan_dibatalkan_state.dart';

/// A bloc that manages the state of a PesananDibatalkan
/// according to the event that is dispatched to it.
class PesananDibatalkanBloc
    extends Bloc<PesananDibatalkanEvent, PesananDibatalkanState> {
  PesananDibatalkanBloc(super.initialState) {
    on<PesananDibatalkanInitialEvent>(_onInitialize);
  }

  _onInitialize(
    PesananDibatalkanInitialEvent event,
    Emitter<PesananDibatalkanState> emit,
  ) async {}
}
