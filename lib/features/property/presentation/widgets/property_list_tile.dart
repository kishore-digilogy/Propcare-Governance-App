import 'package:flutter/material.dart';

import '../../domain/entities/property_entity.dart';

/// Reusable list tile widget for a [PropertyEntity].
class PropertyListTile extends StatelessWidget {
  final PropertyEntity property;

  const PropertyListTile({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.apartment)),
        title: Text(property.name),
        subtitle: Text(property.address),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: navigate to property detail
        },
      ),
    );
  }
}
