class TicketActionState {
  final bool isPanicLoading;
  final bool isRouteDownloadLoading;

  const TicketActionState({
    this.isPanicLoading = false,
    this.isRouteDownloadLoading = false,
  });

  TicketActionState copyWith({
    bool? isPanicLoading,
    bool? isRouteDownloadLoading,
  }) {
    return TicketActionState(
      isPanicLoading: isPanicLoading ?? this.isPanicLoading,
      isRouteDownloadLoading:
          isRouteDownloadLoading ?? this.isRouteDownloadLoading,
    );
  }
}
