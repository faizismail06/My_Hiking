class ResRouteCentres {
  final bool status;
  final String message;
  final Gunung gunung;
  final List<Jalur> data; // List dari jalur

  ResRouteCentres({
    required this.status,
    required this.message,
    required this.gunung,
    required this.data,
  });

  factory ResRouteCentres.fromJson(Map<String, dynamic> json) {
    return ResRouteCentres(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      gunung: Gunung.fromJson(json['gunung']),
      data: List<Jalur>.from(
          json['gunung']['data'].map((x) => Jalur.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'gunung': gunung.toJson(),
      'data': List<dynamic>.from(data.map((x) => x.toJson())),
    };
  }
}

class Gunung {
  final int id;
  final String nama;
  final int ketinggian;
  final String province;
  String? gambar;
  final List<Jalur> data; // Tambahkan data sebagai List<Jalur>

  Gunung({
    required this.id,
    required this.nama,
    required this.ketinggian,
    required this.province,
    required this.data,
    this.gambar,
  });

  factory Gunung.fromJson(Map<String, dynamic> json) {
    return Gunung(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      ketinggian: json['ketinggian'] ?? 0,
      province: json['province'] ?? '',
      gambar: json['gambar'] ?? 'URL Gambar Tidak Tersedia',
      data: json['data'] != null
          ? List<Jalur>.from(json['data'].map((x) => Jalur.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nama": nama,
      "ketinggian": ketinggian,
      "province": province,
      'gambar': gambar,
      "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
  }
}

class ResDetailRouteCentres {
  final bool status;
  final String message;
  final Jalur jalur; // Data jalur utama
  final Gunung gunung; // Data gunung sebagai properti langsung

  ResDetailRouteCentres({
    required this.status,
    required this.message,
    required this.jalur,
    required this.gunung,
  });

  factory ResDetailRouteCentres.fromJson(Map<String, dynamic> json) {
    return ResDetailRouteCentres(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      jalur: Jalur.fromJson(json['jalur']),
      gunung: Gunung.fromJson(
          json['jalur']['gunung']), // Ambil gunung dari dalam jalur
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'jalur': jalur.toJson(),
      'gunung': gunung.toJson(),
    };
  }
}

class Jalur {
  final int id;
  final String nama;
  final String? deskripsi;
  final String mapBasecamp;
  final String? village;
  final String? district;
  final String? regency;
  final String? province;
  final int jarak;
  final String? gambar;
  final int biaya;

  Jalur({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.mapBasecamp,
    this.village,
    this.district,
    this.regency,
    this.province,
    required this.jarak,
    this.gambar,
    required this.biaya,
  });

  factory Jalur.fromJson(Map<String, dynamic> json) {
    return Jalur(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'],
      mapBasecamp: json['map_basecamp'],
      village: json['village'],
      district: json['district'],
      regency: json['regency'],
      province: json['province'],
      jarak: json['jarak'] ?? 0,
      gambar: json['gambar']?? "Gambar tidak tersedia",
      biaya: json['biaya'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nama": nama,
      "deskripsi": deskripsi,
      "map_basecamp": mapBasecamp,
      "village": village,
      "district": district,
      "regency": regency,
      "province": province,
      "jarak": jarak,
      "gambar": gambar,
      "biaya": biaya,
    };
  }
}

class ApiResponse {
  final bool status;
  final String message;
  final Gunung gunung;

  ApiResponse({
    required this.status,
    required this.message,
    required this.gunung,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      gunung: Gunung.fromJson(json['gunung']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "gunung": gunung.toJson(),
    };
  }
}
