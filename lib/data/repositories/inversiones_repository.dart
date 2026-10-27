import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/inversion_historica_model.dart';

/// Repositorio para la consulta de Inversión Histórica de Proyectos (/inversiones/historicas).
class InversionesRepository {
  final ApiClient _client;

  InversionesRepository(this._client);

  /// Consulta el consolidado histórico de inversión en proyectos
  Future<InversionesHistoricasResponse> getInversionesHistoricas() async {
    final response = await _client.get(ApiConstants.inversionesHistoricas);

    if (response is Map<String, dynamic>) {
      return InversionesHistoricasResponse.fromJson(response);
    }

    throw Exception('Formato de respuesta inválido en ${ApiConstants.inversionesHistoricas}');
  }
}
