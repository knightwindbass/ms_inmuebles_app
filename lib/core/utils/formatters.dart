import 'package:intl/intl.dart';

/// Formateadores utilitarios para moneda, metraje, porcentajes y fechas.
class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 1,
  );

  static final NumberFormat _percentFormat = NumberFormat.percentPattern();

  static final NumberFormat _currencyNoDecimalsFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _integerFormat = NumberFormat('#,##0', 'en_US');

  static String currency(num? amount) {
    if (amount == null) return '\$0.00';
    return _currencyFormat.format(amount);
  }

  static String currencyNoDecimals(num? amount) {
    if (amount == null) return '\$0';
    return _currencyNoDecimalsFormat.format(amount);
  }

  static String number(num? amount) {
    if (amount == null) return '0';
    return _integerFormat.format(amount);
  }

  static String compactCurrency(num? amount) {
    if (amount == null) return '\$0';
    return _compactCurrencyFormat.format(amount);
  }

  static String percentage(num? value) {
    if (value == null) return '0%';
    // Si viene como entero o float (ej: 85.5 en vez de 0.855), normalizar
    if (value > 1.0) {
      return '${value.toStringAsFixed(1)}%';
    }
    return _percentFormat.format(value);
  }

  /// Formateador inteligente y compacto para metraje (m²)
  static String area(num? sqm) {
    if (sqm == null || sqm <= 0) return '';
    if (sqm >= 1000000) {
      final millions = sqm / 1000000;
      final formatted = millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 2);
      return '$formatted M m²';
    }
    if (sqm >= 100000) {
      final thousands = sqm / 1000;
      final formatted = thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1);
      return '$formatted k m²';
    }
    final format = NumberFormat('#,##0.##', 'en_US');
    return '${format.format(sqm)} m²';
  }

  static String date(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'es').format(parsed);
    } catch (_) {
      try {
        final parsed = DateTime.parse(dateStr);
        return DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {
        return dateStr;
      }
    }
  }

  static int daysRemaining(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0;
    try {
      final target = DateTime.parse(dateStr);
      final now = DateTime.now();
      return target.difference(DateTime(now.year, now.month, now.day)).inDays;
    } catch (_) {
      return 0;
    }
  }
}
