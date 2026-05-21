import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [rules_screen],
/// and is typically used to hold data that is passed between
/// different parts of the application.
class RuleModel extends Equatable {
  final int id;
  final int trailId;
  final String description;

  const RuleModel({
    required this.id,
    required this.trailId,
    required this.description,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json'); // Debug print
    return RuleModel(
      id: json['id'] ?? 0,
      trailId: json['jalur_id'] ??
          0, // Keep 'jalur_id' as it's the API response field name
      description: json['description'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, trailId, description];

  RuleModel copyWith({
    int? id,
    int? trailId,
    String? description,
  }) {
    return RuleModel(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      description: description ?? this.description,
    );
  }
}
