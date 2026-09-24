import 'package:equatable/equatable.dart';

/// Pure Dart Failure hierarchy mapping caught exceptions to domain-level failures
abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'An unexpected error occurred']);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Local storage operation failed']);
}

class SerializationFailure extends Failure {
  const SerializationFailure([super.message = 'Data serialization error']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Entity not found']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation constraint violated']);
}
