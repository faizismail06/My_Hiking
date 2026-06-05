part of 'ticket_bloc.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object> get props => [];
}

class TicketInitialEvent extends TicketEvent {
  final int pesananId;

  const TicketInitialEvent({required this.pesananId});

  @override
  List<Object> get props => [pesananId];
}

class TicketAddAnggotaEvent extends TicketEvent {
  final int pesananId;
  final int userId;

  const TicketAddAnggotaEvent({required this.pesananId, required this.userId});

  @override
  List<Object> get props => [pesananId, userId];
}

class TicketLoadDataEvent extends TicketEvent {
  final int pesananId;

  const TicketLoadDataEvent({required this.pesananId});

  @override
  List<Object> get props => [pesananId];
}
