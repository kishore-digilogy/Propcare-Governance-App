import 'package:equatable/equatable.dart';

/// Events handled by [PropertyBloc].
abstract class PropertyEvent extends Equatable {
  const PropertyEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers fetching all properties.
class FetchPropertiesEvent extends PropertyEvent {
  const FetchPropertiesEvent();
}
