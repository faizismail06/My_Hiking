import 'package:myhiking/models/model.dart';

class TrailScreenModel {
  final String name;
  final String description; // Deskripsi jalur
  final String location; // Lokasi detail (gabungan alamat)
  final String gambar;
  final int distance; // Jarak
  final String mapBasecamp;
  final Gunung gunung; // Informasi gunung
  final double? latitude;
  final double? longitude;

  TrailScreenModel({
    required this.name,
    required this.description,
    required this.location,
    required this.distance,
    required this.mapBasecamp,
    required this.gunung,
    required this.gambar,
    this.latitude,
    this.longitude,
  });

  /// Membuat model dari ResDetailRouteCentres
  factory TrailScreenModel.fromResDetailRouteCentres(ResDetailRouteCentres data) {
    return TrailScreenModel(
      name: data.jalur.nama,
      description: data.jalur.deskripsi ?? '',
      location:
          "${data.jalur.village}, ${data.jalur.district}, ${data.jalur.regency}, ${data.jalur.province}",
      distance: data.jalur.jarak,
      gunung: data.gunung,
      mapBasecamp: data.jalur.mapBasecamp,
      gambar: data.jalur.gambar ?? "gambar tidak ada",
      latitude: data.jalur.latitude,
      longitude: data.jalur.longitude,
    );
  }
  String get maps => mapBasecamp;
}
