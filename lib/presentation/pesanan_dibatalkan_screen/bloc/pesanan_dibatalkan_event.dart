part of 'pesanan_dibatalkan_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// PesananDibatalkan widget.
/// 
/// Events must be immutable and implement the [Equatable] interface.
class PesananDibatalkanEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the PesananDibatalkan widget is 
/// first created.
class PesananDibatalkanInitialEvent extends PesananDibatalkanEvent {
  @override
  List<Object?> get props => [];
}
