part of 'tiket_saya_bloc.dart';

/// Abstract class for all events
class TiketSayaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event dispatched when the widget is first created
class TiketSayaInitialEvent extends TiketSayaEvent {
  @override
  List<Object?> get props => [];
}

/// Event dispatched when the user ID is received
class TiketSayaUserIdEvent extends TiketSayaEvent {
  final String userId;

  TiketSayaUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
