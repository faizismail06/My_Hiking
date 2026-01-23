import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/pop_up_checkout_model.dart';
part 'pop_up_checkout_event.dart';
part 'pop_up_checkout_state.dart';

/// A bloc that manages the state of a PopUpCheckout according to the event tha
class PopUpCheckoutBloc extends Bloc<PopUpCheckoutEvent, PopUpCheckoutState> {
  PopUpCheckoutBloc(super.initialState) {
    on<PopUpCheckoutInitialEvent>(_onInitialize);
  }

  _onInitialize(
    PopUpCheckoutInitialEvent event,
    Emitter<PopUpCheckoutState> emit,
  ) async {}
}