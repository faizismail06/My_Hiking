import 'package:equatable/equatable.dart';
import 'transactionlist_item_model.dart';

class TransactionModel extends Equatable {
  TransactionModel({
    this.transactionlistItemList = const [],
  });

  List<TransactionItemModel> transactionlistItemList;

  TransactionModel copyWith({
    List<TransactionItemModel>? transactionlistItemList,
  }) {
    return TransactionModel(
      transactionlistItemList:
          transactionlistItemList ?? this.transactionlistItemList,
    );
  }

  @override
  List<Object?> get props => [transactionlistItemList];
}
