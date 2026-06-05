import 'package:equatable/equatable.dart';

/// This class is used in the [recentclimbinglist_item_widget] screen.
// ignore_for_file: must_be_immutable
class RecentclimbinglistItemModel extends Equatable {
  RecentclimbinglistItemModel({
    this.id,
    this.tanggalNaik,
    this.tanggalTurun,
    this.gunung,
    this.status,
  });

  String? id;
  String? tanggalNaik;
  String? tanggalTurun;
  String? gunung;
  String? status;

  // Constructor untuk menyalin model dengan update nilai tertentu
  RecentclimbinglistItemModel copyWith({
    String? id,
    String? tanggalNaik,
    String? tanggalTurun,
    String? gunung,
    String? status,
  }) {
    return RecentclimbinglistItemModel(
      id: id ?? this.id,
      tanggalNaik: tanggalNaik ?? this.tanggalNaik,
      tanggalTurun: tanggalTurun ?? this.tanggalTurun,
      gunung: gunung ?? this.gunung,
      status: status ?? this.status,
    );
  }

  // Factory method untuk membuat model dari JSON
  factory RecentclimbinglistItemModel.fromJson(Map<String, dynamic> json) {
    return RecentclimbinglistItemModel(
      id: json['id']?.toString(),
      tanggalNaik: json['tanggal_naik'],
      tanggalTurun: json['tanggal_turun'],
      gunung: json['gunung'],
      status: json['status'],
    );
  }

  @override
  List<Object?> get props => [id, tanggalNaik, tanggalTurun, gunung, status];
}
