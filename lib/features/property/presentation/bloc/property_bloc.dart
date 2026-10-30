import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_properties.dart';
import 'property_event.dart';
import 'property_state.dart';

/// BLoC responsible for the property feature.
class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final GetProperties getProperties;

  PropertyBloc({required this.getProperties}) : super(const PropertyInitial()) {
    on<FetchPropertiesEvent>(_onFetchProperties);
  }

  Future<void> _onFetchProperties(
    FetchPropertiesEvent event,
    Emitter<PropertyState> emit,
  ) async {
    emit(const PropertyLoading());

    final result = await getProperties(const NoParams());

    result.fold(
      (failure) => emit(PropertyError(message: failure.message)),
      (properties) => emit(PropertyLoaded(properties: properties)),
    );
  }
}
