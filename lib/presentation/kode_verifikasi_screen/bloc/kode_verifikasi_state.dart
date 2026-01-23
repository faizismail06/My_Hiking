part of 'kode_verifikasi_bloc.dart';

/// Represents the state of KodeVerifikasi in the application.

// ignore_for_file: must_be_immutable
class KodeVerifikasiState extends Equatable {
  KodeVerifikasiState(this.passwordController, this.kodeVerifikasiModelobj);

  TextEditingController? passwordController;
  KodeVerifikasiModel? kodeVerifikasiModelobj;

  @override
  List<Object?> get props => [passwordController, kodeVerifikasiModelobj];

  KodeVerifikasiState copyWith({
    TextEditingController? passwordController,
    KodeVerifikasiModel? kodeVerifikasiModelobj,
  }) {
    return KodeVerifikasiState(
      passwordController ?? this.passwordController,
      kodeVerifikasiModelobj ?? this.kodeVerifikasiModelobj,
    );
  }
}
