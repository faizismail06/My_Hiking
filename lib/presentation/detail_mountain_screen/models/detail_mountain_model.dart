import 'package:myhiking/models/model.dart';

class DetailMountainModel {
  final String name;
  final int elevation;
  final String province;
  final double height; // Menambahkan properti height
  final String? gambar;

  DetailMountainModel({
    required this.name,
    required this.elevation,
    required this.province,
    required this.height, // Menambahkan parameter height
    required this.gambar,
  });

  // Konstruktor untuk membuat DetailMountainModel dari Gunung
  factory DetailMountainModel.fromGunung(Gunung gunung) {
    return DetailMountainModel(
      name: gunung.nama,
      elevation: gunung.ketinggian,
      province: gunung.province,
      height: gunung.ketinggian
          .toDouble(), // Misalnya ketinggian digunakan untuk height
      gambar: gunung.gambar,
    );
  }

  // Metode untuk mengubah DetailMountainModel menjadi Map JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'elevation': elevation,
      'province': province,
      'height': height, // Menambahkan height ke dalam JSON
      'gambar': gambar,
    };
  }
}
