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
      gunung: Gunung.fromJson(json['mountain']),
      data: List<Jalur>.from(
          json['mountain']['data'].map((x) => Jalur.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'mountain': gunung.toJson(),
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
  final double? latitude;
  final double? longitude;
  final List<Jalur> data; // Tambahkan data sebagai List<Jalur>

  Gunung({
    required this.id,
    required this.nama,
    required this.ketinggian,
    required this.province,
    required this.data,
    this.gambar,
    this.latitude,
    this.longitude,
  });

  factory Gunung.fromJson(Map<String, dynamic> json) {
    return Gunung(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      ketinggian: json['ketinggian'] ?? 0,
      province: json['province'] ?? '',
      gambar: json['gambar'] ?? 'URL Gambar Tidak Tersedia',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
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
  final DssEvaluation? dss;

  ResDetailRouteCentres({
    required this.status,
    required this.message,
    required this.jalur,
    required this.gunung,
    this.dss,
  });

  factory ResDetailRouteCentres.fromJson(Map<String, dynamic> json) {
    return ResDetailRouteCentres(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      jalur: Jalur.fromJson(json['trail']),
      gunung: Gunung.fromJson(
          json['trail']['mountain']), // Ambil mountain dari dalam trail
      dss: json['dss'] != null ? DssEvaluation.fromJson(json['dss']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'trail': jalur.toJson(),
      'mountain': gunung.toJson(),
      'dss': dss?.toJson(),
    };
  }
}

class DssEvaluation {
  final String riskLevel;
  final String recommendation;
  final String message;
  final double routeScore;
  final double weatherScoreFinal;
  final double finalScore;
  final List<String> reasoning;
  final DssWeather? weather;

  DssEvaluation({
    required this.riskLevel,
    required this.recommendation,
    required this.message,
    required this.routeScore,
    required this.weatherScoreFinal,
    required this.finalScore,
    required this.reasoning,
    this.weather,
  });

  factory DssEvaluation.fromJson(Map<String, dynamic> json) {
    return DssEvaluation(
      riskLevel: (json['risk_level'] ?? 'safe').toString(),
      recommendation: (json['recommendation'] ?? 'recommended').toString(),
      message: (json['message'] ?? '').toString(),
      routeScore: double.tryParse((json['route_score'] ?? 0).toString()) ?? 0,
      weatherScoreFinal:
          double.tryParse((json['weather_score_final'] ?? 0).toString()) ?? 0,
      finalScore: double.tryParse((json['final_score'] ?? 0).toString()) ?? 0,
      reasoning: (json['reasoning'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      weather: json['weather'] is Map<String, dynamic>
          ? DssWeather.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'recommendation': recommendation,
      'message': message,
      'route_score': routeScore,
      'weather_score_final': weatherScoreFinal,
      'final_score': finalScore,
      'reasoning': reasoning,
      'weather': weather?.toJson(),
    };
  }
}

class DssWeather {
  final int code;
  final String condition;
  final double? temperature;
  final double? windSpeed;

  DssWeather({
    required this.code,
    required this.condition,
    this.temperature,
    this.windSpeed,
  });

  factory DssWeather.fromJson(Map<String, dynamic> json) {
    return DssWeather(
      code: int.tryParse((json['code'] ?? 0).toString()) ?? 0,
      condition: (json['condition'] ?? '').toString(),
      temperature: json['temperature'] != null
          ? double.tryParse(json['temperature'].toString())
          : null,
      windSpeed: json['wind_speed'] != null
          ? double.tryParse(json['wind_speed'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'condition': condition,
      'temperature': temperature,
      'wind_speed': windSpeed,
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
  final double jarak;
  final double? elevasi;
  final double? durasi;
  final String? tingkatKesulitan;
  final String? gambar;
  final int biaya;
  final double? latitude;
  final double? longitude;

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
    this.elevasi,
    this.durasi,
    this.tingkatKesulitan,
    this.gambar,
    required this.biaya,
    this.latitude,
    this.longitude,
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
      jarak: double.tryParse((json['jarak'] ?? 0).toString()) ?? 0.0,
      elevasi: json['elevasi'] != null ? double.tryParse(json['elevasi'].toString()) : null,
      durasi: json['durasi'] != null ? double.tryParse(json['durasi'].toString()) : null,
      tingkatKesulitan: json['tingkat_kesulitan']?.toString(),
      gambar: json['gambar']?? "Gambar tidak tersedia",
      biaya: json['biaya'] ?? 0,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
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
      "elevasi": elevasi,
      "durasi": durasi,
      "tingkat_kesulitan": tingkatKesulitan,
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
