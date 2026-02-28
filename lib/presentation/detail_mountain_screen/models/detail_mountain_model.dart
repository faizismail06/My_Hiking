import 'package:myhiking/models/model.dart';

class DetailMountainModel {
  final String name;
  final int elevation;
  final String province;
  final double height; // Menambahkan properti height
  final String? gambar;
  final double? latitude;
  final double? longitude;

  DetailMountainModel({
    required this.name,
    required this.elevation,
    required this.province,
    required this.height, // Menambahkan parameter height
    required this.gambar,
    this.latitude,
    this.longitude,
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
      latitude: gunung.latitude,
      longitude: gunung.longitude,
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
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
