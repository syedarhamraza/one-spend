/// Typed Exception Hierarchy for OneSpend Data and Platform operations
abstract class AppException implements Exception {
  final String message;
  final dynamic cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

class StorageException extends AppException {
  const StorageException([super.message = 'Storage operation failed', super.cause]);
}

class SerializationException extends AppException {
  const SerializationException([super.message = 'JSON serialization/deserialization failed', super.cause]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Requested entity not found', super.cause]);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation constraint violated', super.cause]);
}
