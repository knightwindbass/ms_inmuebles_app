import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../logic/auth_provider.dart';
import '../models/app_version_model.dart';
import '../../presentation/widgets/app_update_dialog.dart';

/// Servicio para consultar actualizaciones remotas de la app y desplegar el diálogo de notificación.
class AppUpdateService {
  static bool _hasPromptedThisSession = false;

  /// Consulta el endpoint /app/version en el servidor
  static Future<AppVersionInfo?> fetchVersionInfo(ApiClient client) async {
    try {
      final res = await client.get(ApiConstants.appVersion);
      if (res is Map<String, dynamic>) {
        return AppVersionInfo.fromJson(res);
      }
    } catch (_) {
      // Manejo silencioso de red
    }
    return null;
  }

  /// Verifica si hay una actualización disponible y muestra el diálogo en pantalla
  static Future<void> checkAndShowPrompt(
    BuildContext context, {
    bool manualCheck = false,
  }) async {
    // Si no es revisión manual y ya se mostró en esta sesión, no insistir en cada pestaña
    if (!manualCheck && _hasPromptedThisSession) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final info = await fetchVersionInfo(auth.apiClient);

    if (!context.mounted) return;

    if (info != null) {
      final hasNewVersion = info.hasUpdate(
        currentVersion: ApiConstants.currentAppVersion,
        currentBuild: ApiConstants.currentBuildNumber,
      );

      if (hasNewVersion) {
        _hasPromptedThisSession = true;
        final isMandatory = info.isMandatory ||
            info.isBlockedDueToMinVersion(
              currentVersion: ApiConstants.currentAppVersion,
              currentBuild: ApiConstants.currentBuildNumber,
            );

        showDialog(
          context: context,
          barrierDismissible: !isMandatory,
          builder: (_) => AppUpdateDialog(updateInfo: info),
        );
        return;
      }
    }

    // Si fue una comprobación manual desde el menú de opciones y no hay actualización
    if (manualCheck && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tu aplicación está al día con la última versión (v${ApiConstants.currentAppVersion} build ${ApiConstants.currentBuildNumber}).',
          ),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
