import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/storage/session_storage.dart';
import '../data/repositories/dashboard_repository.dart';

/// Manejo del estado de autenticación y configuración multi-tenant.
class AuthProvider extends ChangeNotifier {
  final SessionStorage _session;
  late ApiClient _apiClient;
  late DashboardRepository _dashboardRepo;

  bool _isTestingConnection = false;
  String? _errorMessage;

  AuthProvider(this._session) {
    _initClients();
  }

  void _initClients() {
    _apiClient = ApiClient(session: _session);
    _dashboardRepo = DashboardRepository(_apiClient);
  }

  SessionStorage get session => _session;
  ApiClient get apiClient => _apiClient;
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

  Future<void> logout() async {
    await _session.clear();
    _initClients();
    notifyListeners();
  }
}
