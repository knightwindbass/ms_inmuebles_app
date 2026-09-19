import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/tenant_perfil_model.dart';

/// Repositorio para consultar información del Tenant y personalización corporativa (/tenant/perfil).
class TenantRepository {
  final ApiClient _client;

  TenantRepository(this._client);

  /// Obtiene el perfil, banner institucional y logotipo del Tenant activo.
  Future<TenantPerfilModel> getPerfil() async {
    final response = await _client.get(ApiConstants.tenantPerfil);

    if (response is Map<String, dynamic>) {
      return TenantPerfilModel.fromJson(response);
    }

    throw Exception('Formato de respuesta inválido en /tenant/perfil');
  }
}
