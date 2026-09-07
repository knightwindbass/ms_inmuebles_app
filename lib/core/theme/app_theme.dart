import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuración de tema visual minimalista y diccionario visual para MS Inmuebles SaaS.
class AppTheme {
  // Paleta de Colores
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFF2563EB); // Royal Blue
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Colors.white;
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);

  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF151C2C);
  static const Color textMainDark = Color(0xFFF1F5F9);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Diccionario Visual: Colores por Estado (Coherencia Web)
  static const Color statusDisponible = Color(0xFF3B82F6); // Azul #3b82f6
  static const Color statusRentado = Color(0xFF10B981); // Verde #10b981
  static const Color statusMantenimiento = Color(0xFFF59E0B); // Naranja #f59e0b
  static const Color statusInactivo = Color(0xFF94A3B8); // Gris #94a3b8

  /// Helper para el Color de la "Pastilla" (Badge) según el Estado
  static Color getColorForEstado(String? estado) {
    switch (estado?.toLowerCase().trim()) {
      case 'disponible':
        return statusDisponible; // Azul #3b82f6
      case 'rentado':
        return statusRentado; // Verde #10b981
      case 'mantenimiento':
        return statusMantenimiento; // Naranja #f59e0b
      case 'inactivo':
      default:
        return statusInactivo; // Gris #94a3b8
    }
  }

  /// Helper para el Ícono según la Tipología
  static IconData getIconForType(String? tipo) {
    switch (tipo?.trim()) {
      case 'Edificio':
        return Icons.domain;
      case 'Bodega':
        return Icons.warehouse;
      case 'Local':
        return Icons.storefront;
      case 'Oficina':
        return Icons.business_center;
      case 'Terreno':
        return Icons.landscape;
      default:
        return Icons.home_work;
    }
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surfaceLight,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textMainLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textMainLight),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: textMainLight),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: textMainLight),
        bodyLarge: const TextStyle(color: textMainLight),
        bodyMedium: const TextStyle(color: textMutedLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surfaceDark,
        error: Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textMainDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textMainDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: textMainDark),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: textMainDark),
        bodyLarge: const TextStyle(color: textMainDark),
        bodyMedium: const TextStyle(color: textMutedDark),
      ),
    );
  }
}
