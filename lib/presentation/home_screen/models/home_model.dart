import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [home_screen],
/// and is typically used to hold data that is passed between different parts of the application.
// Model untuk home (mungkin untuk tujuan lain)
class HomeModel extends Equatable {
  const HomeModel();

  HomeModel copyWith() {
    return const HomeModel();
  }

  @override
  List<Object?> get props => [];
}
