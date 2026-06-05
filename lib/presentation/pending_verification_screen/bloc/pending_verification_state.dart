part of 'pending_verification_bloc.dart';

class PendingVerificationState extends Equatable {
  final PendingVerificationModel? pendingVerificationModelObj;
  final bool isLoading;
  final String? error;

  const PendingVerificationState({
    this.pendingVerificationModelObj,
    this.isLoading = false,
    this.error,
  });

  PendingVerificationState copyWith({
    PendingVerificationModel? pendingVerificationModelObj,
    bool? isLoading,
    String? error,
  }) {
    return PendingVerificationState(
      pendingVerificationModelObj:
          pendingVerificationModelObj ?? this.pendingVerificationModelObj,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [pendingVerificationModelObj, isLoading, error];
}
