import 'package:myhiking/models/model.dart';

class TrailScreenModel {
  final String name;
  final String description; // Deskripsi jalur
  final String location; // Lokasi detail (gabungan alamat)
  final String gambar;
  final double distance; // Jarak
  final String mapBasecamp;
  final Gunung gunung; // Informasi gunung
  final double? latitude;
  final double? longitude;
  final DssEvaluation? dss;
  final RoutePreview? routePreview;
  final List<TrailPost> posts;

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
    this.dss,
    this.routePreview,
    this.posts = const [],
  });

  /// Membuat model dari ResDetailRouteCentres
  factory TrailScreenModel.fromResDetailRouteCentres(
      ResDetailRouteCentres data) {
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
      dss: data.dss,
      routePreview: data.jalur.routePreview,
      posts: data.jalur.posts,
    );
  }
  String get maps => mapBasecamp;

  String get distanceLabel {
    return distance % 1 == 0
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(2);
  }
}
