import 'package:equatable/equatable.dart';

import '../../domain/entities/property_entity.dart';

/// States emitted by [PropertyBloc].
abstract class PropertyState extends Equatable {
  const PropertyState();

  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {
  const PropertyInitial();
}

class PropertyLoading extends PropertyState {
  const PropertyLoading();
}

class PropertyLoaded extends PropertyState {
  final List<PropertyEntity> properties;
  const PropertyLoaded({required this.properties});

  @override
  List<Object?> get props => [properties];
}

class PropertyError extends PropertyState {
  final String message;
  const PropertyError({required this.message});

  @override
  List<Object?> get props => [message];
}
