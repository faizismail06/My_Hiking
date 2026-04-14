import 'package:myhiking/models/model.dart';

// Model untuk data gunung
class HomelistItemModel {
  int? id;
  String? namaGunung;
  String? gambar;
  // String? province;
  Province? province;
  DssEvaluation? dss;
  double? latitude;
  double? longitude;
  int? ketinggian;

  var title;

  HomelistItemModel({
    this.id,
    this.namaGunung,
    this.gambar,
    this.province,
    this.dss,
    this.latitude,
    this.longitude,
    this.ketinggian,
  });

  factory HomelistItemModel.fromJson(Map<String, dynamic> json) {
    final rawProvince = json["province"];

    return HomelistItemModel(
      id: json['id'],
      namaGunung: json['nama'] ?? 'Nama Gunung Tidak Tersedia',
      gambar: json['gambar'] ?? 'URL Gambar Tidak Tersedia',
      latitude: json['latitude'] is String ? double.tryParse(json['latitude']) : (json['latitude'] as num?)?.toDouble(),
      longitude: json['longitude'] is String ? double.tryParse(json['longitude']) : (json['longitude'] as num?)?.toDouble(),
      ketinggian: json['ketinggian'] is String ? int.tryParse(json['ketinggian']) : (json['ketinggian'] as num?)?.toInt(),
      // province: json['province_name'] ?? 'Provinsi Tidak Tersedia',
      province: rawProvince is Map<String, dynamic>
          ? Province.fromJson(rawProvince)
          : rawProvince is Map
              ? Province.fromJson(Map<String, dynamic>.from(rawProvince))
              : rawProvince is String
                  ? Province(id: 0, name: rawProvince)
                  : null,
        dss: json['dss'] is Map<String, dynamic>
          ? DssEvaluation.fromJson(json['dss'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': namaGunung,
      'gambar': gambar,
      // 'province': province,
      "province": province?.toJson(),
      'dss': dss?.toJson(),
    };
  }

  static List<HomelistItemModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => HomelistItemModel.fromJson(item)).toList();
  }
}

class Province {
  int id;
  String name;

  Province({
    required this.id,
    required this.name,
  });

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
