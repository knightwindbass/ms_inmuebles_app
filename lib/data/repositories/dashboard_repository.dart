import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_kpi_model.dart';
import '../models/tenant_perfil_model.dart';

/// Repositorio para consultar métricas e inteligencia de negocio (/dashboard/resumen).
class DashboardRepository {
  final ApiClient _client;

  DashboardRepository(this._client);

  Future<DashboardKpiModel> getResumen({int? padreId}) async {
    final queryParams = <String, dynamic>{};
    if (padreId != null && padreId > 0) {
      queryParams['padre_id'] = padreId;
    }

    final response = await _client.get(
      ApiConstants.dashboardResumen,
      queryParameters: queryParams,
    );

    if (response is Map<String, dynamic>) {
      return DashboardKpiModel.fromJson(response);
    }

    throw Exception('Formato de respuesta inválido en /dashboard/resumen');
  }

  /// Consulta opcional de personalización de Tenant (/tenant/perfil).
  Future<TenantPerfilModel?> getTenantPerfil() async {
    try {
      final response = await _client.get(ApiConstants.tenantPerfil);
      if (response is Map<String, dynamic>) {
        return TenantPerfilModel.fromJson(response);
      }
    } catch (_) {
      // Si el endpoint aún no está desplegado o falla, no detiene el funcionamiento del dashboard
    }
    return null;
  }
}
