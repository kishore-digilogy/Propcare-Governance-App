import '../../domain/entities/property_entity.dart';

/// Data model extends the domain entity.
/// Adds JSON serialisation / deserialisation logic.
class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.name,
    required super.address,
    required super.ownerId,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      ownerId: json['owner_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address, 'owner_id': ownerId};
  }
}
