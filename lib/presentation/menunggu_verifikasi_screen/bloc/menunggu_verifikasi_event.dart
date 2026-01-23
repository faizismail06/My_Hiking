part of 'menunggu_verifikasi_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// MenungguVerifikasi widget.
///
class MenungguVerifikasiEvent extends Equatable {
  const MenungguVerifikasiEvent();

  @override
  List<Object?> get props => [];
}

class FetchMenungguVerifikasiData extends MenungguVerifikasiEvent {
  final int pesananId;

  const FetchMenungguVerifikasiData(this.pesananId);

  @override
  List<Object?> get props => [pesananId];
}
