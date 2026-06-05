class MidtransPaymentState {
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final String? paymentUrl;
  final bool paymentOpenedInBrowser;

  const MidtransPaymentState({
    this.isLoading = true,
    this.hasError = false,
    this.errorMessage = '',
    this.paymentUrl,
    this.paymentOpenedInBrowser = false,
  });

  MidtransPaymentState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    String? paymentUrl,
    bool clearPaymentUrl = false,
    bool? paymentOpenedInBrowser,
  }) {
    return MidtransPaymentState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentUrl: clearPaymentUrl ? null : (paymentUrl ?? this.paymentUrl),
      paymentOpenedInBrowser:
          paymentOpenedInBrowser ?? this.paymentOpenedInBrowser,
    );
  }
}
