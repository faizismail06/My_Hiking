part of 'kode_verifikasi_bloc.dart';

// Abstract class for all events that can be dispatched from the
// KodeVerifikasi widget.

// Events must be immutable and implement the [Equatable] interface.
class KodeVerifikasiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Event that is dispatched when the KodeVerifikasi widget is first created.
class KodeVerifikasiInitialEvent extends KodeVerifikasiEvent {
  @override
  List<Object?> get props => [];
}