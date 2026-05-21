part of 'pop_up_pw_diganti_bloc.dart';

/// Abstract class for all events that can be dispatched from the
/// PopUpPwDiganti widget.
///
/// Events must be immutable and implement the [Equatable] interface.
class PopUpPwDigantiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the PopUpPwDiganti widget is first created.
class PopUpPwDigantiInitialEvent extends PopUpPwDigantiEvent {
  @override
  List<Object?> get props => [];
}
