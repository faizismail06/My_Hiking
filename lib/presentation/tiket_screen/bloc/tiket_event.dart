part of 'tiket_bloc.dart';

abstract class TiketEvent extends Equatable {
  const TiketEvent();

  @override
  List<Object> get props => [];
}

class TiketInitialEvent extends TiketEvent {
  final int pesananId;

  const TiketInitialEvent({required this.pesananId});

  @override
  List<Object> get props => [pesananId];
}

class TiketAddAnggotaEvent extends TiketEvent {
  final int pesananId;
  final int userId;

  const TiketAddAnggotaEvent({required this.pesananId, required this.userId});

  @override
  List<Object> get props => [pesananId, userId];
}

class TiketLoadDataEvent extends TiketEvent {
  final int pesananId;

  const TiketLoadDataEvent({required this.pesananId});

  @override
  List<Object> get props => [pesananId];
}
