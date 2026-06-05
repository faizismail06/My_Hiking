class ResTrailModel {
  final bool status;
  final String message;
  final TrailModel trail;

  ResTrailModel(
      {required this.status, required this.message, required this.trail});

  factory ResTrailModel.fromJson(Map<String, dynamic> json) {
    return ResTrailModel(
      status: json['status'],
      message: json['message'],
      trail: TrailModel.fromJson(json['trail']),
    );
  }
}


class TrailModel {
  final int id;
  final String nama;
  final String village;
  final String district;
  final String regency;
  final String province;
  final String gambar;
  final double biaya;
  final Mountain gunung;

  TrailModel({
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

  // Factory method to convert JSON to TrailModel
  factory TrailModel.fromJson(Map<String, dynamic> json) {
    return TrailModel(
      id: json['id'],
      nama: json['nama'],
      village: json['village'],
      district: json['district'],
      regency: json['regency'],
      province: json['province'],
      gambar: json['gambar'],
      biaya: json['biaya'].toDouble(),
      gunung: Mountain.fromJson(json['mountain']),
    );
  }

  // Method to convert object to JSON
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

class Mountain {
  final int id;
  final String nama;
  final double ketinggian;
  final String province;

  Mountain({
    required this.id,
    required this.nama,
    required this.ketinggian,
    required this.province,
  });

  // Factory method to convert JSON to Mountain
  factory Mountain.fromJson(Map<String, dynamic> json) {
    return Mountain(
      id: json['id'],
      nama: json['nama'],
      ketinggian: json['ketinggian'].toDouble(),
      province: json['province'],
    );
  }

  // Method to convert object to JSON
  Map<String, dynamic> toJson() => {
        "id": id,
        "nama": nama,
        "ketinggian": ketinggian,
        "province": province,
      };
}
