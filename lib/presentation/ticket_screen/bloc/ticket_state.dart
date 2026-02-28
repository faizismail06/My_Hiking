part of 'ticket_bloc.dart';

abstract class TicketState extends Equatable {
  const TicketState();

  @override
  List<Object> get props => [];
}

class TicketInitialState extends TicketState {}

class TicketLoadingState extends TicketState {}

class TicketLoadedState extends TicketState {
  final TicketModel ticketModel;

  const TicketLoadedState({required this.ticketModel});

  @override
  List<Object> get props => [ticketModel];
}

class TicketErrorState extends TicketState {
  final String message;

  const TicketErrorState({required this.message});

  @override
  List<Object> get props => [message];
}
