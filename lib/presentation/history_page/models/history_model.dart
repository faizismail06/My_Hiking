import 'package:equatable/equatable.dart';
import 'recentclimbinglist_item_model.dart';

/// This class defines the variables used in the [history_page],
/// and is typically used to hold data that is passed between different parts of the application.
// ignore_for_file: must_be_immutable
class HistoryModel extends Equatable {
  HistoryModel({this.recentclimbinglistItemList = const []});

  List<RecentclimbinglistItemModel> recentclimbinglistItemList;

  HistoryModel copyWith({
    List<RecentclimbinglistItemModel>? recentclimbinglistItemList,
  }) {
    return HistoryModel(
      recentclimbinglistItemList:
          recentclimbinglistItemList ?? this.recentclimbinglistItemList,
    );
  }

  @override
  List<Object?> get props => [recentclimbinglistItemList];
}
