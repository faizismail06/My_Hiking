import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [tata_tertib_screen],
/// and is typically used to hold data that is passed between
/// different parts of the application.
class TataTertibModel extends Equatable {
  final int id;
  final int jalurId;
  final String description;

  const TataTertibModel({
    required this.id,
    required this.jalurId,
    required this.description,
  });

  factory TataTertibModel.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json'); // Debug print
    return TataTertibModel(
      id: json['id'] ?? 0,
      jalurId: json['jalur_id'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, jalurId, description];

  TataTertibModel copyWith({
    int? id,
    int? jalurId,
    String? description,
  }) {
    return TataTertibModel(
      id: id ?? this.id,
      jalurId: jalurId ?? this.jalurId,
      description: description ?? this.description,
    );
  }
}
