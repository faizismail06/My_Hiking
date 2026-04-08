import 'package:flutter_bloc/flutter_bloc.dart';

import 'ticket_action_state.dart';

class TicketActionCubit extends Cubit<TicketActionState> {
  TicketActionCubit() : super(const TicketActionState());

  void setPanicLoading(bool value) {
    emit(state.copyWith(isPanicLoading: value));
  }

  void setRouteDownloadLoading(bool value) {
    emit(state.copyWith(isRouteDownloadLoading: value));
  }
}
