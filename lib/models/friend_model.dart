class FriendModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePicture;
  final int? friendshipId;
  final String? friendshipStatus;

  FriendModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePicture,
    this.friendshipId,
    this.friendshipStatus,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      profilePicture: json['profile_picture'],
      friendshipId: json['friendship_id'],
      friendshipStatus: json['friendship_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'friendship_id': friendshipId,
      'friendship_status': friendshipStatus,
    };
  }
}

class PendingRequestModel {
  final int friendshipId;
  final FriendModel user;
  final DateTime createdAt;

  PendingRequestModel({
    required this.friendshipId,
    required this.user,
    required this.createdAt,
  });

  factory PendingRequestModel.fromJson(Map<String, dynamic> json) {
    return PendingRequestModel(
      friendshipId: json['friendship_id'],
      user: FriendModel.fromJson(json['user']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
