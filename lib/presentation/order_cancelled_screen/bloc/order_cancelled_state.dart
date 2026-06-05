part of 'order_cancelled_bloc.dart';

/// Represents the state of OrderCancelled in the application.
// ignore_for_file: must_be_immutable
class OrderCancelledState extends Equatable {
  OrderCancelledState({this.orderCancelledModelObj});

  OrderCancelledModel? orderCancelledModelObj;

  @override
  List<Object?> get props => [orderCancelledModelObj];

  OrderCancelledState copyWith({OrderCancelledModel? orderCancelledModelObj}) {
    return OrderCancelledState(
      orderCancelledModelObj:
          orderCancelledModelObj ?? this.orderCancelledModelObj,
    );
  }
}
