part of 'riwayat_transaksi_bloc.dart';

class RiwayatTransaksiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RiwayatTransaksiInitialEvent extends RiwayatTransaksiEvent {
  @override
  List<Object?> get props => [];
}

class RiwayatTransaksiUserIdEvent extends RiwayatTransaksiEvent {
  final String userId;

  RiwayatTransaksiUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
