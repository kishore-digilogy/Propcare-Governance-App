import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server failure.'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache failure.'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network failure.'});
}
