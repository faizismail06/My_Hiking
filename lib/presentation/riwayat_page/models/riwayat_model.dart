import 'package:equatable/equatable.dart';
import 'recentclimbinglist_item_model.dart';

/// This class defines the variables used in the [riwayat_page],
/// and is typically used to hold data that is passed between different parts of the application.
// ignore_for_file: must_be_immutable
class RiwayatModel extends Equatable {
  RiwayatModel({this.recentclimbinglistItemList = const []});

  List<RecentclimbinglistItemModel> recentclimbinglistItemList;

  RiwayatModel copyWith({
    List<RecentclimbinglistItemModel>? recentclimbinglistItemList,
  }) {
    return RiwayatModel(
      recentclimbinglistItemList:
          recentclimbinglistItemList ?? this.recentclimbinglistItemList,
    );
  }

  @override
  List<Object?> get props => [recentclimbinglistItemList];
}
