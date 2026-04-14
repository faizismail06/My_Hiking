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

  factory ResRouteCentres.fromJson(Map<String, dynamic> json) {\n    // Handle null mountain data safely\n    final mountainData = json['mountain'] as Map<String, dynamic>? ?? {};\n    final jalurList = mountainData['data'] as List? ?? [];\n    \n    return ResRouteCentres(\n      status: (json['status'] as bool?) ?? false,\n      message: (json['message'] as String?) ?? '',\n      gunung: Gunung.fromJson(mountainData),\n      data: jalurList.isNotEmpty\n          ? List<Jalur>.from(jalurList.map((x) => Jalur.fromJson(x as Map<String, dynamic>)))\n          : [],\n    );\n  }

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
    // Safely parse latitude and longitude with null checks
    double? parsedLat;
    if (json['latitude'] != null) {
      try {
        parsedLat = double.parse(json['latitude'].toString());
      } catch (e) {
        parsedLat = null;
      }
    }

    double? parsedLng;
    if (json['longitude'] != null) {
      try {
        parsedLng = double.parse(json['longitude'].toString());
      } catch (e) {
        parsedLng = null;
      }
    }

    return Gunung(
      id: json['id'] as int? ?? 0,
      nama: (json['nama'] as String?) ?? '',
      ketinggian: json['ketinggian'] as int? ?? 0,
      province: (json['province'] as String?) ?? 'Unknown',
      gambar: (json['gambar'] as String?) ??
          (json['gambar_gunung'] as String?) ??
          'assets/images/img_error.png',
      latitude: parsedLat,
      longitude: parsedLng,
      data: json['data'] != null
          ? List<Jalur>.from((json['data'] as List)
              .map((x) => Jalur.fromJson(x as Map<String, dynamic>)))
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

class RoutePreview {
  final String source;
  final int totalPoints;
  final int displayPoints;
  final RoutePoint? start;
  final RoutePoint? end;
  final Map<String, double>? bbox;
  final List<RoutePoint> points;
  final String? updatedAt;

  RoutePreview({
    required this.source,
    required this.totalPoints,
    required this.displayPoints,
    required this.points,
    this.start,
    this.end,
    this.bbox,
    this.updatedAt,
  });

  factory RoutePreview.fromJson(Map<String, dynamic> json) {
    final bboxRaw = json['bbox'] as Map<String, dynamic>?;
    final pointsRaw = (json['points'] as List?) ?? const [];
    return RoutePreview(
      source: (json['source'] ?? 'manual').toString(),
      totalPoints: int.tryParse((json['total_points'] ?? 0).toString()) ?? 0,
      displayPoints:
          int.tryParse((json['display_points'] ?? 0).toString()) ?? 0,
      start: json['start'] is Map<String, dynamic>
          ? RoutePoint.fromJson(json['start'])
          : null,
      end: json['end'] is Map<String, dynamic>
          ? RoutePoint.fromJson(json['end'])
          : null,
      bbox: bboxRaw?.map(
        (key, value) => MapEntry(key, double.tryParse(value.toString()) ?? 0),
      ),
      points: pointsRaw
          .whereType<Map>()
          .map((item) => RoutePoint.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'total_points': totalPoints,
      'display_points': displayPoints,
      'start': start?.toJson(),
      'end': end?.toJson(),
      'bbox': bbox,
      'points': points.map((point) => point.toJson()).toList(),
      'updated_at': updatedAt,
    };
  }
}

class RoutePoint {
  final double lat;
  final double lng;
  final double? ele;
  final String? time;

  RoutePoint({
    required this.lat,
    required this.lng,
    this.ele,
    this.time,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      lat: double.tryParse((json['lat'] ?? 0).toString()) ?? 0,
      lng: double.tryParse((json['lng'] ?? json['lon'] ?? 0).toString()) ?? 0,
      ele: json['ele'] != null ? double.tryParse(json['ele'].toString()) : null,
      time: json['time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'ele': ele,
      'time': time,
    };
  }
}

class TrailPost {
  final int id;
  final String name;
  final int sequence;
  final double lat;
  final double lng;
  final double? elevation;
  final String iconType;
  final String? description;

  TrailPost({
    required this.id,
    required this.name,
    required this.sequence,
    required this.lat,
    required this.lng,
    this.elevation,
    required this.iconType,
    this.description,
  });

  factory TrailPost.fromJson(Map<String, dynamic> json) {
    return TrailPost(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      sequence: int.tryParse((json['sequence'] ?? 0).toString()) ?? 0,
      lat: double.tryParse((json['lat'] ?? json['latitude'] ?? 0).toString()) ??
          0,
      lng: double.tryParse(
              (json['lng'] ?? json['lon'] ?? json['longitude'] ?? 0)
                  .toString()) ??
          0,
      elevation: json['elevation'] != null
          ? double.tryParse(json['elevation'].toString())
          : null,
      iconType: (json['icon_type'] ?? 'signpost').toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sequence': sequence,
      'lat': lat,
      'lng': lng,
      'elevation': elevation,
      'icon_type': iconType,
      'description': description,
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
  final RoutePreview? routePreview;
  final List<TrailPost> posts;

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
    this.routePreview,
    this.posts = const [],
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
      elevasi: json['elevasi'] != null
          ? double.tryParse(json['elevasi'].toString())
          : null,
      durasi: json['durasi'] != null
          ? double.tryParse(json['durasi'].toString())
          : null,
      tingkatKesulitan: json['tingkat_kesulitan']?.toString(),
      gambar: json['gambar'] ?? "Gambar tidak tersedia",
      biaya: json['biaya'] ?? 0,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      routePreview: json['route_preview'] is Map<String, dynamic>
          ? RoutePreview.fromJson(json['route_preview'])
          : null,
      posts: (json['posts'] as List?)
              ?.whereType<Map>()
              .map(
                  (item) => TrailPost.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
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
      "latitude": latitude,
      "longitude": longitude,
      "route_preview": routePreview?.toJson(),
      "posts": posts.map((item) => item.toJson()).toList(),
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
