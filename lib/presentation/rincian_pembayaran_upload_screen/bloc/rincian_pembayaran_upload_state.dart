part of 'rincian_pembayaran_upload_bloc.dart';

/// Represents the state of RincianPembayaranUpload in the application.
// ignore_for_file: must_be_immutable
class RincianPembayaranUploadState extends Equatable {
  final RincianPembayaranUploadModel? rincianPembayaranUploadModelObj;
  final bool isLoading;
  final String error;

  // Constructor with optional parameters.
  RincianPembayaranUploadState({
    this.rincianPembayaranUploadModelObj,
    this.isLoading = false,
    this.error = '',
  });

  // Initial state factory
  factory RincianPembayaranUploadState.initial() {
    return RincianPembayaranUploadState(
      isLoading: false,
      error: '',
      rincianPembayaranUploadModelObj: null,
    );
  }

  // Helper method to create a new state with modified values
  RincianPembayaranUploadState copyWith({
    bool? isLoading,
    String? error,
    RincianPembayaranUploadModel? rincianPembayaranUploadModelObj,
  }) {
    return RincianPembayaranUploadState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      rincianPembayaranUploadModelObj: rincianPembayaranUploadModelObj ??
          this.rincianPembayaranUploadModelObj,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, error, rincianPembayaranUploadModelObj];
}
