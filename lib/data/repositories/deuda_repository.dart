import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/deuda_inmobiliaria_model.dart';

/// Repositorio para la gestión de pasivos y riesgos inmobiliarios (/pasivos/dashboard).
class DeudaRepository {
  final ApiClient _client;

  DeudaRepository(this._client);

  /// Consulta el dashboard consolidado de deuda inmobiliaria
  Future<DeudaDashboardModel> getDeudaDashboard() async {
    final response = await _client.get(ApiConstants.pasivosDashboard);

    if (response is Map<String, dynamic>) {
      return DeudaDashboardModel.fromJson(response);
    }

    throw Exception('Formato de respuesta inválido en /pasivos/dashboard');
  }

  /// Consulta el flujo neto financiero consolidado (Rentas vs Deuda)
  Future<Map<String, dynamic>?> getFlujoNeto() async {
    try {
      final response = await _client.get(ApiConstants.pasivosFlujoNeto);
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {
      // Manejo silencioso si falla
    }
    return null;
  }
}
