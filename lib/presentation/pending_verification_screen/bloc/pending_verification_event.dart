part of 'pending_verification_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// PendingVerification widget.
///
class PendingVerificationEvent extends Equatable {
  const PendingVerificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchPendingVerificationData extends PendingVerificationEvent {
  final int pesananId;

  const FetchPendingVerificationData(this.pesananId);

  @override
  List<Object?> get props => [pesananId];
}
