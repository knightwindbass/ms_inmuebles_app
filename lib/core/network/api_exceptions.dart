/// Manejo centralizado de excepciones y errores HTTP de la API MS Inmuebles.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Credenciales inválidas o faltantes (x-api-key / x-tenant-id)'])
      : super(message: message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Acceso denegado al tenant especificado'])
      : super(message: message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Recurso no encontrado'])
      : super(message: message, statusCode: 404);
}

class BadRequestException extends ApiException {
  BadRequestException([String message = 'Petición inválida o rechazada por el servidor'])
      : super(message: message, statusCode: 400);
}

class ServerErrorException extends ApiException {
  ServerErrorException([String message = 'Error interno en el servidor'])
      : super(message: message, statusCode: 500);
}

class NetworkException extends ApiException {
  NetworkException([String message = 'Error de conexión de red o timeout'])
      : super(message: message, statusCode: null);
}
