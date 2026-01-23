part of 'menunggu_verifikasi_bloc.dart';

class MenungguVerifikasiState extends Equatable {
  final MenungguVerifikasiModel? menungguVerifikasiModelObj;
  final bool isLoading;
  final String? error;

  const MenungguVerifikasiState({
    this.menungguVerifikasiModelObj,
    this.isLoading = false,
    this.error,
  });

  MenungguVerifikasiState copyWith({
    MenungguVerifikasiModel? menungguVerifikasiModelObj,
    bool? isLoading,
    String? error,
  }) {
    return MenungguVerifikasiState(
      menungguVerifikasiModelObj:
          menungguVerifikasiModelObj ?? this.menungguVerifikasiModelObj,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [menungguVerifikasiModelObj, isLoading, error];
}
