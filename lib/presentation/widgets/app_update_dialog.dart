import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/app_version_model.dart';

/// Modal emergente ejecutivo para notificar al usuario sobre una nueva versión de la aplicación.
class AppUpdateDialog extends StatelessWidget {
  final AppVersionInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final urlStr = updateInfo.effectiveDownloadUrl;
    if (urlStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace de descarga aún no está configurado en el servidor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir el enlace: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const colorTeal = Color(0xFF0D9488);
    const colorBlue = Color(0xFF2563EB);

    final isMandatory = updateInfo.isMandatory ||
        updateInfo.isBlockedDueToMinVersion(
          currentVersion: ApiConstants.currentAppVersion,
          currentBuild: ApiConstants.currentBuildNumber,
        );

    final notesLines = updateInfo.notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Ícono de Actualización con Gradiente
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [colorTeal, colorBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colorTeal.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              // 2. Título
              Text(
                updateInfo.title.isNotEmpty
                    ? updateInfo.title
                    : '¡Nueva versión disponible!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 8),

              // 3. Píldora de Comparación de Versiones
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v${ApiConstants.currentAppVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colorTeal,
                      ),
                    ),
                    Text(
                      'v${updateInfo.latestVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colorTeal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Banner si es obligatoria
              if (isMandatory) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Actualización requerida para continuar sincronizando datos.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 5. Novedades y Notas de la versión
              if (notesLines.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Novedades de esta versión:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: notesLines.map((line) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 6),
                                child: Icon(Icons.check_circle_outline_rounded, size: 12, color: colorTeal),
                              ),
                              Expanded(
                                child: Text(
                                  line.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 6. Botones de Acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Actualizar Ahora',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTeal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _launchUpdateUrl(context),
                ),
              ),

              if (!isMandatory) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Recordar más tarde',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
