part of 'rincian_pembayaran_upload_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// RincianPembayaranUpload widget.
/// Events must be immutable and implement the [Equatable] interface.
class RincianPembayaranUploadEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that triggers fetching the rincian pembayaran data.
class FetchRincianPembayaranUploadEvent extends RincianPembayaranUploadEvent {
  final String transactionId;
  String? filePath;
  final bool isLoading;
  final String? error;

  FetchRincianPembayaranUploadEvent({
    required this.transactionId,
    this.filePath,
    required this.isLoading,
    this.error,
  });

  @override
  List<Object?> get props => [transactionId, filePath, isLoading, error];
}
