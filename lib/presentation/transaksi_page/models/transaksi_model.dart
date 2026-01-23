import 'package:equatable/equatable.dart';
import 'transactionlist_item_model.dart';

class TransaksiModel extends Equatable {
  TransaksiModel({this.transactionlistItemList = const [],});

  List<TransactionModel> transactionlistItemList;

  TransaksiModel copyWith({
    List<TransactionModel>? transactionlistItemList,
  }) {
    return TransaksiModel(
      transactionlistItemList:
          transactionlistItemList ?? this.transactionlistItemList,
    );
  }

  @override
  List<Object?> get props => [transactionlistItemList];
}