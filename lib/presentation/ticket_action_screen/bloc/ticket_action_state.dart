class TicketActionState {
  final bool isPanicLoading;
  final bool isRouteDownloadLoading;
  final bool isCancelOrderLoading;

  const TicketActionState({
    this.isPanicLoading = false,
    this.isRouteDownloadLoading = false,
    this.isCancelOrderLoading = false,
  });

  TicketActionState copyWith({
    bool? isPanicLoading,
    bool? isRouteDownloadLoading,
    bool? isCancelOrderLoading,
  }) {
    return TicketActionState(
      isPanicLoading: isPanicLoading ?? this.isPanicLoading,
      isRouteDownloadLoading:
          isRouteDownloadLoading ?? this.isRouteDownloadLoading,
      isCancelOrderLoading: isCancelOrderLoading ?? this.isCancelOrderLoading,
    );
  }
}
