import 'package:flutter/foundation.dart';

/// Modelo de datos para la información de control remoto de versiones (/app/version).
class AppVersionInfo {
  final bool success;
  final String latestVersion;
  final int buildNumber;
  final String minRequiredVersion;
  final bool isMandatory;
  final String title;
  final String notes;
  final String downloadUrlAndroid;
  final String downloadUrlIos;
  final String updatedAt;

  AppVersionInfo({
    required this.success,
    required this.latestVersion,
    required this.buildNumber,
    required this.minRequiredVersion,
    required this.isMandatory,
    required this.title,
    required this.notes,
    required this.downloadUrlAndroid,
    required this.downloadUrlIos,
    required this.updatedAt,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      success: json['success'] == true,
      latestVersion: (json['latest_version'] ?? '2.5.4').toString().trim(),
      buildNumber: _toInt(json['build_number'], 30),
      minRequiredVersion: (json['min_required_version'] ?? '2.5.0').toString().trim(),
      isMandatory: json['is_mandatory'] == true || json['is_mandatory'] == 1,
      title: (json['title'] ?? 'Nueva actualización disponible').toString(),
      notes: (json['notes'] ?? '').toString(),
      downloadUrlAndroid: (json['download_url_android'] ?? '').toString(),
      downloadUrlIos: (json['download_url_ios'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  /// URL de descarga según el sistema operativo del dispositivo
  String get effectiveDownloadUrl {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (downloadUrlIos.isNotEmpty) return downloadUrlIos;
    }
    return downloadUrlAndroid;
  }

  /// Comprueba si la versión del backend es superior a la versión instalada en el dispositivo
  bool hasUpdate({required String currentVersion, required int currentBuild}) {
    // 1. Comparar Build Number incremental si ambos son mayores a 0
    if (buildNumber > currentBuild) {
      return true;
    }

    // 2. Comparar SemVer (mayor.menor.parche)
    return _compareSemVer(latestVersion, currentVersion) > 0;
  }

  /// Comprueba si el dispositivo está por debajo de la versión mínima requerida
  bool isBlockedDueToMinVersion({required String currentVersion, required int currentBuild}) {
    if (isMandatory) return true;
    if (minRequiredVersion.isEmpty) return false;
    return _compareSemVer(minRequiredVersion, currentVersion) > 0;
  }

  static int _compareSemVer(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  static int _toInt(dynamic val, int fallback) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }
}
