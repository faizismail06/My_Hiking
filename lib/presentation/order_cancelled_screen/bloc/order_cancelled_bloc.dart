import 'package:equatable/equatable.dart';
import '../../../../core/app_export.dart';
import '../models/order_cancelled_model.dart';

part 'order_cancelled_event.dart';
part 'order_cancelled_state.dart';

/// A bloc that manages the state of a OrderCancelled
/// according to the event that is dispatched to it.
class OrderCancelledBloc
    extends Bloc<OrderCancelledEvent, OrderCancelledState> {
  OrderCancelledBloc(super.initialState) {
    on<OrderCancelledInitialEvent>(_onInitialize);
  }

  _onInitialize(
    OrderCancelledInitialEvent event,
    Emitter<OrderCancelledState> emit,
  ) async {}
}
