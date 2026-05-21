part of 'pop_up_checkout_bloc.dart';

/// Represents the state of PopUpCheckout in the application.

// ignore_for_file: must_be_immutable
class PopUpCheckoutState extends Equatable {
  PopUpCheckoutState({this.popUpCheckoutModelobj});

  PopUpCheckoutModel? popUpCheckoutModelobj;

  @override
  List<Object?> get props => [popUpCheckoutModelobj];

  PopUpCheckoutState copywith({PopUpCheckoutModel? popUpCheckoutModelobj}) {
    return PopUpCheckoutState(
      popUpCheckoutModelobj:
          popUpCheckoutModelobj ?? this.popUpCheckoutModelobj,
    );
  }
}
