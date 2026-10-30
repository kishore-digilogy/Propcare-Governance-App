import 'package:equatable/equatable.dart';

/// Example domain entity – replace with real PropCare entities.
class PropertyEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String ownerId;

  const PropertyEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [id, name, address, ownerId];
}
