import 'package:myhiking/models/trail_model.dart';

class BookingModel {
  final String name;
  final String location; // Lokasi detail (gabungan alamat)
  final String gambar;
  final double biaya;
  final Mountain mountain; // Informasi gunung

  BookingModel({
    required this.name,
    required this.location,
    required this.biaya,
    required this.mountain,
    required this.gambar,
  });

  /// Membuat model dari ResTrailModel yang berisi satu trail
  static BookingModel resTrailModelFromJson(ResTrailModel data) {
    return BookingModel(
      name: data.trail.nama,
      location:
          "${data.trail.village}, ${data.trail.district}, ${data.trail.regency}, ${data.trail.province}",
      biaya: data.trail.biaya,
      mountain: data.trail.gunung,
      gambar: data.trail.gambar ??
          "gambar tidak ada", // Default message for missing image
    );
  }
}
