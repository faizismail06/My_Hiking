  import 'package:equatable/equatable.dart';
  import 'homelist_item_model.dart';
  // Model untuk beranda awal
  class BerandaInitialModel extends Equatable {
    BerandaInitialModel({this.homelistItemList = const []});

    List<HomelistItemModel> homelistItemList;

    BerandaInitialModel copyWith({List<HomelistItemModel>? homelistItemList}) {
      return BerandaInitialModel(
        homelistItemList: homelistItemList ?? this.homelistItemList,
      );
    }

    @override
    List<Object?> get props => [homelistItemList];
  }