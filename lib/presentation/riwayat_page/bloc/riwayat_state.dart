part of 'riwayat_bloc.dart';

/// Represents the state of Riwayat in the application.
// ignore_for_file: must_be_immutable
class RiwayatState extends Equatable {
  final RiwayatModel? riwayatModelObj;
  final String? userId;
  final String errorMessage;

  RiwayatState({
    this.riwayatModelObj,
    this.userId,
    this.errorMessage = '',
  });

  RiwayatState copyWith({
    RiwayatModel? riwayatModelObj,
    String? userId,
    String? errorMessage,
  }) {
    return RiwayatState(
      riwayatModelObj: riwayatModelObj ?? this.riwayatModelObj,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [riwayatModelObj, userId, errorMessage];
}
