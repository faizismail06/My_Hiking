// Model untuk data gunung
class HomelistItemModel {
  int? id;
  String? namaGunung;
  String? gambar;
  // String? province;
  Province? province;

  var title;

  HomelistItemModel({
    this.id,
    this.namaGunung,
    this.gambar,
    this.province,
  });

  factory HomelistItemModel.fromJson(Map<String, dynamic> json) {
    return HomelistItemModel(
      id: json['id'],
      namaGunung: json['nama'] ?? 'Nama Gunung Tidak Tersedia',
      gambar: json['gambar'] ?? 'URL Gambar Tidak Tersedia',
      // province: json['province_name'] ?? 'Provinsi Tidak Tersedia',
      province:
          json["province"] != null ? Province.fromJson(json["province"]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': namaGunung,
      'gambar': gambar,
      // 'province': province,
      "province": province?.toJson(),
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
