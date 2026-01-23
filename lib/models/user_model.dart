class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final DateTime? emailVerifiedAt;
  final int? level;
  final String? address;
  final int? nik;
  final int? emergencyPhone;
  final String? profilePicture;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.emailVerifiedAt,
    this.level,
    this.address,
    this.nik,
    this.emergencyPhone,
    this.profilePicture,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone'] != null ? json['phone'].toString() : null,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      level: json['level'],
      address: json['address'],
      nik: json['nik'],
      emergencyPhone: json['emergency_phone'],
      profilePicture: json['profile_picture'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'level': level,
      'address': address,
      'nik': nik,
      'emergency_phone': emergencyPhone,
      'profile_picture': profilePicture,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
