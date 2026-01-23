part of 'detail_mountain_bloc.dart';

/// Event yang dapat dikirim ke DetailMountainBloc
abstract class DetailMountainEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event untuk inisialisasi DetailMountain
class DetailMountainInitialEvent extends DetailMountainEvent {
  final int idGunung; // ID gunung untuk diambil datanya

  DetailMountainInitialEvent(this.idGunung);

  @override
  List<Object?> get props => [idGunung];
}
