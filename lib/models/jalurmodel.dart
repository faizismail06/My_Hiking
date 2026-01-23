class ResJalurModel {
  final bool status;
  final String message;
  final JalurModel jalur;

  ResJalurModel(
      {required this.status, required this.message, required this.jalur});

  factory ResJalurModel.fromJson(Map<String, dynamic> json) {
    return ResJalurModel(
      status: json['status'],
      message: json['message'],
      jalur: JalurModel.fromJson(json['jalur']),
    );
  }
}


class JalurModel {
  final int id;
  final String nama;
  final String village;
  final String district;
  final String regency;
  final String province;
  final String gambar;
  final double biaya;
  final Gunung gunung;

  JalurModel({
    required this.id,
    required this.nama,
    required this.village,
    required this.district,
    required this.regency,
    required this.province,
    required this.gambar,
    required this.biaya,
    required this.gunung,
  });

  // Factory method untuk mengonversi JSON ke JalurModel
  factory JalurModel.fromJson(Map<String, dynamic> json) {
    return JalurModel(
      id: json['id'],
      nama: json['nama'],
      village: json['village'],
      district: json['district'],
      regency: json['regency'],
      province: json['province'],
      gambar: json['gambar'],
      biaya: json['biaya'].toDouble(),
      gunung: Gunung.fromJson(json['gunung']),
    );
  }

  // Method untuk mengonversi objek menjadi JSON
  Map<String, dynamic> toJson() => {
        "id": id,
        "nama": nama,
        "village": village,
        "district": district,
        "regency": regency,
        "province": province,
        "gambar": gambar,
        "biaya": biaya,
        "gunung": gunung.toJson(),
      };
}

class Gunung {
  final int id;
  final String nama;
  final double ketinggian;
  final String province;

  Gunung({
    required this.id,
    required this.nama,
    required this.ketinggian,
    required this.province,
  });

  // Factory method untuk mengonversi JSON ke Gunung
  factory Gunung.fromJson(Map<String, dynamic> json) {
    return Gunung(
      id: json['id'],
      nama: json['nama'],
      ketinggian: json['ketinggian'].toDouble(),
      province: json['province'],
    );
  }

  // Method untuk mengonversi objek menjadi JSON
  Map<String, dynamic> toJson() => {
        "id": id,
        "nama": nama,
        "ketinggian": ketinggian,
        "province": province,
      };
}
