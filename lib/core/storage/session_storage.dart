import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Almacenamiento local persistente para las credenciales multi-tenant del usuario.
class SessionStorage {
  static const String _keyBaseUrl = 'msinm_base_url';
  static const String _keyApiKey = 'msinm_api_key';
  static const String _keyTenantId = 'msinm_tenant_id';
  static const String _keyTenantBanner = 'msinm_tenant_banner';
  static const String _keyTenantLogo = 'msinm_tenant_logo';
  static const String _keyTenantName = 'msinm_tenant_name';
  static const String _keyTenantSlogan = 'msinm_tenant_slogan';

  final SharedPreferences _prefs;

  SessionStorage(this._prefs);

  static Future<SessionStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionStorage(prefs);
  }

  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? ApiConstants.defaultBaseUrl;
  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  String get tenantId => _prefs.getString(_keyTenantId) ?? '';

  String? get cachedTenantBanner => _prefs.getString(_keyTenantBanner);
  String? get cachedTenantLogo => _prefs.getString(_keyTenantLogo);
  String? get cachedTenantName => _prefs.getString(_keyTenantName);
  String? get cachedTenantSlogan => _prefs.getString(_keyTenantSlogan);

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

  Future<void> saveTenantBranding({
    String? banner,
    String? logo,
    String? name,
    String? slogan,
  }) async {
    if (banner != null && banner.isNotEmpty) {
      await _prefs.setString(_keyTenantBanner, banner);
    }
    if (logo != null && logo.isNotEmpty) {
      await _prefs.setString(_keyTenantLogo, logo);
    }
    if (name != null && name.isNotEmpty) {
      await _prefs.setString(_keyTenantName, name);
    }
    if (slogan != null && slogan.isNotEmpty) {
      await _prefs.setString(_keyTenantSlogan, slogan);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_keyBaseUrl);
    await _prefs.remove(_keyApiKey);
    await _prefs.remove(_keyTenantId);
    await _prefs.remove(_keyTenantBanner);
    await _prefs.remove(_keyTenantLogo);
    await _prefs.remove(_keyTenantName);
    await _prefs.remove(_keyTenantSlogan);
  }
}
