import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/inmueble_model.dart';

/// Repositorio para la gestión y consulta de inmuebles (/inmuebles).
class InmueblesRepository {
  final ApiClient _client;

  InmueblesRepository(this._client);

  Future<List<InmuebleModel>> getInmuebles({
    String? estado,
    String? tipo,
    String? buscar,
    String? propietario,
    int? padreId,
    String? orden,
  }) async {
    final queryParams = <String, dynamic>{};
    if (buscar != null && buscar.trim().isNotEmpty) queryParams['buscar'] = buscar.trim();
    if (estado != null && estado.trim().isNotEmpty) {
      queryParams['f_estado'] = estado.trim();
      queryParams['estado'] = estado.trim();
    }
    if (tipo != null && tipo.trim().isNotEmpty) {
      queryParams['f_tipo'] = tipo.trim();
      queryParams['tipo'] = tipo.trim();
    }
    if (propietario != null && propietario.trim().isNotEmpty) {
      queryParams['f_propietario'] = propietario.trim();
    }
    if (padreId != null && padreId > 0) queryParams['padre_id'] = padreId;
    if (orden != null && orden.trim().isNotEmpty) queryParams['orden'] = orden.trim();

    final response = await _client.get(
      ApiConstants.inmuebles,
      queryParameters: queryParams,
    );

    // Mapeo seguro de la lista desde results, data, o raíz
    dynamic rawList;
    if (response is Map) {
      rawList = response['results'] ?? response['data'] ?? response['inmuebles'] ?? response['items'];
    } else if (response is List) {
      rawList = response;
    }

    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((item) => InmuebleModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  Future<InmuebleModel> getInmuebleDetalle(int id) async {
    final response = await _client.get('${ApiConstants.inmuebles}/$id');

    if (response is Map) {
      final rawData = response['results'] ?? response['data'] ?? response['inmueble'] ?? response;
      if (rawData is Map) {
        return InmuebleModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }

    throw Exception('No se pudo obtener el detalle del inmueble');
  }

  Future<InmuebleModel> createInmueble(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.inmuebles, body: data);
    if (response is Map) {
      final rawData = response['data'] ?? response['results'] ?? response;
      if (rawData is Map) {
        return InmuebleModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }
    throw Exception('Error al crear inmueble');
  }

  Future<InmuebleModel> updateInmueble(int id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConstants.inmuebles}/$id', body: data);
    if (response is Map) {
      final rawData = response['data'] ?? response['results'] ?? response;
      if (rawData is Map) {
        return InmuebleModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }
    throw Exception('Error al actualizar inmueble');
  }

  Future<void> deleteInmueble(int id) async {
    await _client.delete('${ApiConstants.inmuebles}/$id');
  }
}
