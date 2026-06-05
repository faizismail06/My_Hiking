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
      name: gunung.nama.isNotEmpty ? gunung.nama : 'Unknown Mountain',
      elevation: gunung.ketinggian > 0 ? gunung.ketinggian : 0,
      province: gunung.province.isNotEmpty ? gunung.province : 'Unknown Region',
      height: (gunung.ketinggian > 0 ? gunung.ketinggian : 0).toDouble(),
      gambar: (gunung.gambar?.isNotEmpty ?? false)
          ? gunung.gambar
          : 'assets/images/img_error.png',
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
