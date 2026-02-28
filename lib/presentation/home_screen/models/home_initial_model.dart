import 'package:equatable/equatable.dart';
import 'homelist_item_model.dart';

// Model untuk home awal
class HomeInitialModel extends Equatable {
  HomeInitialModel({this.homelistItemList = const []});

  List<HomelistItemModel> homelistItemList;

  HomeInitialModel copyWith({List<HomelistItemModel>? homelistItemList}) {
    return HomeInitialModel(
      homelistItemList: homelistItemList ?? this.homelistItemList,
    );
  }

  @override
  List<Object?> get props => [homelistItemList];
}
