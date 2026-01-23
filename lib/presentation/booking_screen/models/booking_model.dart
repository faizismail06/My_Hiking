import 'package:myhiking/models/jalurmodel.dart';

class BookingModel {
  final String name;
  final String location; // Lokasi detail (gabungan alamat)
  final String gambar;
  final double biaya;
  final Gunung gunung; // Informasi gunung

  BookingModel({
    required this.name,
    required this.location,
    required this.biaya,
    required this.gunung,
    required this.gambar,
  });

  /// Membuat model dari ResJalurModel yang berisi satu jalur
  static BookingModel resJalurModelFromJson(ResJalurModel data) {
    // Return a single BookingModel from the first jalur in the list
    // You can select which jalur to use, here we are using the first one

    return BookingModel(
      name: data.jalur.nama,

      location:
          "${data.jalur.village}, ${data.jalur.district}, ${data.jalur.regency}, ${data.jalur.province}",
      biaya: data.jalur.biaya,
      gunung: data.jalur.gunung,
      gambar: data.jalur.gambar ??
          "gambar tidak ada", // Default message for missing image
    );
  }
}
