import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/storage/session_storage.dart';
import '../data/models/tenant_perfil_model.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/tenant_repository.dart';

/// Manejo del estado de autenticación y configuración multi-tenant.
class AuthProvider extends ChangeNotifier {
  final SessionStorage _session;
  late ApiClient _apiClient;
  late DashboardRepository _dashboardRepo;
  late TenantRepository _tenantRepo;

  TenantPerfilModel? _tenantPerfil;
  bool _isTestingConnection = false;
  String? _errorMessage;

  AuthProvider(this._session) {
    _initClients();
  }

  void _initClients() {
    _apiClient = ApiClient(session: _session);
    _dashboardRepo = DashboardRepository(_apiClient);
    _tenantRepo = TenantRepository(_apiClient);

    // Restaurar branding en caché para evitar pestañeos
    if (_session.cachedTenantBanner != null ||
        _session.cachedTenantLogo != null ||
        _session.cachedTenantName != null) {
      _tenantPerfil = TenantPerfilModel(
        tenantId: _session.tenantId,
        identificador: _session.cachedTenantName,
        appBanner: _session.cachedTenantBanner,
        logo: _session.cachedTenantLogo,
        slogan: _session.cachedTenantSlogan,
      );
    }
  }

  SessionStorage get session => _session;
  ApiClient get apiClient => _apiClient;
  TenantRepository get tenantRepo => _tenantRepo;
  TenantPerfilModel? get tenantPerfil => _tenantPerfil;
  bool get isConfigured => _session.isConfigured;
  bool get isTestingConnection => _isTestingConnection;
  String? get errorMessage => _errorMessage;

  String get baseUrl => _session.baseUrl;
  String get apiKey => _session.apiKey;
  String get tenantId => _session.tenantId;

  Future<bool> saveAndVerifyCredentials({
    required String baseUrl,
    required String apiKey,
    required String tenantId,
  }) async {
    _isTestingConnection = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Guardar temporalmente para probar
      await _session.saveCredentials(
        baseUrl: baseUrl,
        apiKey: apiKey,
        tenantId: tenantId,
      );
      _initClients();

      // Probar petición de resumen
      await _dashboardRepo.getResumen();

      // Intentar sincronizar perfil de marca blanca de inmediato
      await fetchTenantPerfil();

      _isTestingConnection = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isTestingConnection = false;
      notifyListeners();
      return false;
    }
  }

  /// Consulta el perfil de personalización y banner corporativo (/tenant/perfil).
  Future<TenantPerfilModel?> fetchTenantPerfil() async {
    try {
      final perfil = await _tenantRepo.getPerfil();
      _tenantPerfil = perfil;
      await _session.saveTenantBranding(
        banner: perfil.appBanner,
        logo: perfil.logo,
        name: perfil.identificador,
        slogan: perfil.slogan,
      );
      notifyListeners();
      return perfil;
    } catch (_) {
      return _tenantPerfil;
    }
  }

  Future<void> logout() async {
    await _session.clear();
    _tenantPerfil = null;
    _initClients();
    notifyListeners();
  }
}
