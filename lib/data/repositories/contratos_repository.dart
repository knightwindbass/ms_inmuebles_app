import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/contrato_model.dart';

/// Repositorio para la gestión de contratos de arrendamiento (/contratos).
class ContratosRepository {
  final ApiClient _client;

  ContratosRepository(this._client);

  Future<List<ContratoModel>> getContratos({
    String? buscar,
    String? orden,
  }) async {
    final queryParams = <String, dynamic>{};
    if (buscar != null && buscar.trim().isNotEmpty) queryParams['buscar'] = buscar.trim();
    if (orden != null && orden.trim().isNotEmpty) queryParams['orden'] = orden.trim();

    final response = await _client.get(
      ApiConstants.contratos,
      queryParameters: queryParams,
    );

    // Mapeo seguro de la lista desde results, data, o raíz
    dynamic rawList;
    if (response is Map) {
      rawList = response['results'] ?? response['data'] ?? response['contratos'] ?? response['items'];
    } else if (response is List) {
      rawList = response;
    }

    if (rawList is List) {
      final parsed = rawList
          .whereType<Map>()
          .map((item) => ContratoModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return ContratoModel.groupContratos(parsed);
    }

    return [];
  }

  Future<ContratoModel> getContratoDetalle(int id) async {
    final response = await _client.get('${ApiConstants.contratos}/$id');

    dynamic rawData;
    if (response is Map) {
      rawData = response['results'] ?? response['data'] ?? response['contrato'] ?? response;
    } else if (response is List) {
      rawData = response;
    }

    if (rawData is List) {
      final list = rawData
          .whereType<Map>()
          .map((item) => ContratoModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final grouped = ContratoModel.groupContratos(list);
      if (grouped.isNotEmpty) return grouped.first;
    } else if (rawData is Map) {
      return ContratoModel.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw Exception('No se pudo obtener el detalle del contrato');
  }

  Future<ContratoModel> createContrato(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.contratos, body: data);
    if (response is Map) {
      final rawData = response['data'] ?? response['results'] ?? response;
      if (rawData is Map) {
        return ContratoModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }
    throw Exception('Error al registrar contrato');
  }

  Future<ContratoModel> updateContrato(int id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConstants.contratos}/$id', body: data);
    if (response is Map) {
      final rawData = response['data'] ?? response['results'] ?? response;
      if (rawData is Map) {
        return ContratoModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }
    throw Exception('Error al actualizar contrato');
  }
}
