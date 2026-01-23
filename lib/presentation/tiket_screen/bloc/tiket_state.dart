part of 'tiket_bloc.dart';

abstract class TiketState extends Equatable {
  const TiketState();

  @override
  List<Object> get props => [];
}

class TiketInitialState extends TiketState {}

class TiketLoadingState extends TiketState {}

class TiketLoadedState extends TiketState {
  final TiketModel tiketModel;

  const TiketLoadedState({required this.tiketModel});

  @override
  List<Object> get props => [tiketModel];
}

class TiketErrorState extends TiketState {
  final String message;

  const TiketErrorState({required this.message});

  @override
  List<Object> get props => [message];
}
