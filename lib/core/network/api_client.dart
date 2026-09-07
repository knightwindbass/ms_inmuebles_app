import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/session_storage.dart';
import 'api_exceptions.dart';

/// Cliente HTTP centralizado con inyección automática de Headers Multi-Tenant y control de errores.
class ApiClient {
  final SessionStorage _session;
  final http.Client _httpClient;

  ApiClient({
    required SessionStorage session,
    http.Client? httpClient,
  })  : _session = session,
        _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders() {
    return {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerApiKey: _session.apiKey,
      ApiConstants.headerTenantId: _session.tenantId,
    };
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanBaseUrl = _session.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBaseUrl$cleanPath';

    final uri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final queryMap = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryMap[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: queryMap);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decodedBody;
    try {
      final utf8Body = utf8.decode(response.bodyBytes);
      if (utf8Body.isNotEmpty) {
        decodedBody = jsonDecode(utf8Body);
      }
    } catch (_) {
      decodedBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    final errorMessage = (decodedBody is Map && decodedBody['message'] != null)
        ? decodedBody['message'].toString()
        : (decodedBody is String && decodedBody.isNotEmpty ? decodedBody : 'Error en la petición');

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(errorMessage);
      case 401:
        throw UnauthorizedException('No autorizado: Verifica tu x-api-key y x-tenant-id');
      case 403:
        throw ForbiddenException('Acceso prohibido para este tenant');
      case 404:
        throw NotFoundException('Recurso no encontrado: $errorMessage');
      case 500:
      default:
        throw ServerErrorException('Error en el servidor ($response.statusCode): $errorMessage');
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _httpClient
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException('Sin conexión con el servidor. Revisa tu internet o URL base.');
    } on TimeoutException catch (_) {
      throw NetworkException('Tiempo de espera agotado al conectar con el servidor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error de comunicación: $e');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(path);
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException('Sin conexión con el servidor.');
    } on TimeoutException catch (_) {
      throw NetworkException('Tiempo de espera agotado.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error al enviar datos: $e');
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(path);
      final response = await _httpClient
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException('Sin conexión con el servidor.');
    } on TimeoutException catch (_) {
      throw NetworkException('Tiempo de espera agotado.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error al actualizar datos: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await _httpClient
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException('Sin conexión con el servidor.');
    } on TimeoutException catch (_) {
      throw NetworkException('Tiempo de espera agotado.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error al eliminar recurso: $e');
    }
  }
}
