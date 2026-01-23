// To parse this JSON data, do
//
//     final resUser = resUserFromJson(jsonString);

import 'dart:convert';

ResUser resUserFromJson(String str) => ResUser.fromJson(json.decode(str));

String resUserToJson(ResUser data) => json.encode(data.toJson());

class ResUser {
  bool success;
  String message;
  Data data;

  ResUser({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ResUser.fromJson(Map<String, dynamic> json) => ResUser(
        success: json["success"] ?? false,
        message: json["message"] ?? '',
        data: json["data"] != null
            ? Data.fromJson(json["data"])
            : Data(
                id: 0,
                name: '',
                email: '',
                emailVerifiedAt: null,
                level: '',
                address: '',
                nik: '',
                phone: '',
                emergencyPhone: '',
                profilePicture: '',
                dateOfBirth: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
      };
}

class Data {
  final int id;
  final String name;
  final String email;
  final dynamic emailVerifiedAt;
  final String level;
  final String address;
  final String nik;
  final String phone;
  final String emergencyPhone;
  final String profilePicture;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  Data({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerifiedAt,
    required this.level,
    required this.address,
    required this.nik,
    required this.phone,
    required this.emergencyPhone,
    required this.profilePicture,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"] ?? 0,
        name: (json["name"] ?? '').toString(),
        email: (json["email"] ?? '').toString(),
        emailVerifiedAt: json["email_verified_at"],
        level: (json["level"] ?? '').toString(),
        address: (json["address"] ?? '').toString(),
        nik: (json["nik"] ?? '').toString(),
        phone: (json["phone"] ?? '').toString(),
        emergencyPhone: (json["emergency_phone"] ?? '').toString(),
        profilePicture: (json["profile_picture"] ?? '').toString(),
        dateOfBirth: json["date_of_birth"] != null &&
                json["date_of_birth"].toString().isNotEmpty
            ? DateTime.parse(json["date_of_birth"])
            : null,
        createdAt: DateTime.parse(
            json["created_at"] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(
            json["updated_at"] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "email_verified_at": emailVerifiedAt,
        "level": level,
        "address": address,
        "nik": nik,
        "phone": phone,
        "emergency_phone": emergencyPhone,
        "profile_picture": profilePicture,
        "date_of_birth": dateOfBirth?.toIso8601String(),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
      };
}
