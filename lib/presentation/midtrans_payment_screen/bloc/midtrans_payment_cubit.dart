import 'package:flutter_bloc/flutter_bloc.dart';

import 'midtrans_payment_state.dart';

class MidtransPaymentCubit extends Cubit<MidtransPaymentState> {
  MidtransPaymentCubit() : super(const MidtransPaymentState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }

  void setPaymentUrl(String? value) {
    emit(state.copyWith(paymentUrl: value));
  }

  void setError(String message) {
    emit(state.copyWith(
      hasError: true,
      errorMessage: message,
      isLoading: false,
    ));
  }

  void clearError() {
    emit(state.copyWith(hasError: false, errorMessage: ''));
  }

  void setPaymentOpenedInBrowser(bool value) {
    emit(state.copyWith(paymentOpenedInBrowser: value));
  }
}
