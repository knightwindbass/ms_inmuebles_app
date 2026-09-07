import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Almacenamiento local persistente para las credenciales multi-tenant del usuario.
class SessionStorage {
  static const String _keyBaseUrl = 'msinm_base_url';
  static const String _keyApiKey = 'msinm_api_key';
  static const String _keyTenantId = 'msinm_tenant_id';

  final SharedPreferences _prefs;

  SessionStorage(this._prefs);

  static Future<SessionStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionStorage(prefs);
  }

  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? ApiConstants.defaultBaseUrl;
  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  String get tenantId => _prefs.getString(_keyTenantId) ?? '';

  bool get isConfigured => apiKey.trim().isNotEmpty && tenantId.trim().isNotEmpty;

  Future<void> saveCredentials({
    required String baseUrl,
    required String apiKey,
    required String tenantId,
  }) async {
    await _prefs.setString(_keyBaseUrl, baseUrl.trim().replaceAll(RegExp(r'/+$'), ''));
    await _prefs.setString(_keyApiKey, apiKey.trim());
    await _prefs.setString(_keyTenantId, tenantId.trim());
  }

  Future<void> clear() async {
    await _prefs.remove(_keyBaseUrl);
    await _prefs.remove(_keyApiKey);
    await _prefs.remove(_keyTenantId);
  }
}
