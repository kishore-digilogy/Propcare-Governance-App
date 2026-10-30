import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/property_list_tile.dart';

/// Main page for the Property feature.
class PropertyPage extends StatelessWidget {
  const PropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      body: BlocConsumer<PropertyBloc, PropertyState>(
        listener: (context, state) {
          if (state is PropertyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is PropertyLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PropertyLoaded) {
            final properties = state.properties;
            if (properties.isEmpty) {
              return const Center(child: Text('No properties found.'));
            }
            return ListView.builder(
              itemCount: properties.length,
              itemBuilder: (_, index) =>
                  PropertyListTile(property: properties[index]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.read<PropertyBloc>().add(const FetchPropertiesEvent()),
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
