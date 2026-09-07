import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/inquilino_model.dart';

/// Repositorio para la gestión de inquilinos y directorio (/inquilinos).
class InquilinosRepository {
  final ApiClient _client;

  InquilinosRepository(this._client);

  Future<List<InquilinoModel>> getInquilinos() async {
    final response = await _client.get(ApiConstants.inquilinos);

    // Mapeo seguro de la lista desde results, data, o raíz
    dynamic rawList;
    if (response is Map) {
      rawList = response['results'] ?? response['data'] ?? response['inquilinos'] ?? response['items'];
    } else if (response is List) {
      rawList = response;
    }

    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((item) => InquilinoModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  Future<InquilinoModel> createInquilino(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.inquilinos, body: data);
    if (response is Map) {
      final rawData = response['data'] ?? response['results'] ?? response;
      if (rawData is Map) {
        return InquilinoModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }
    throw Exception('Error al registrar inquilino');
  }

  Future<InquilinoModel> updateInquilino(int id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConstants.inquilinos}/$id', body: data);
    if (response is Map) {
      final rawData = response['data'] ?? response['results'] ?? response;
      if (rawData is Map) {
        return InquilinoModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    }
    throw Exception('Error al actualizar inquilino');
  }

  Future<void> deleteInquilino(int id) async {
    await _client.delete('${ApiConstants.inquilinos}/$id');
  }
}
