/// Modelos de datos para el Análisis de Pareto de Renta (Regla 80/20) y Top 10 Corporativo.
class ParetoItemModel {
  final int posicion;
  final String empresa;
  final String ruc;
  final double mrr;
  final int totalLocales;
  final String sucursales;
  final double participacionPct;
  final double acumuladoPct;
  final bool esVital80;

  const ParetoItemModel({
    required this.posicion,
    required this.empresa,
    required this.ruc,
    required this.mrr,
    required this.totalLocales,
    required this.sucursales,
    required this.participacionPct,
    required this.acumuladoPct,
    required this.esVital80,
  });

  /// Retorna un emoji o texto de medalla según la posición
  String get medal {
    switch (posicion) {
      case 1:
        return '🥇 1°';
      case 2:
        return '🥈 2°';
      case 3:
        return '🥉 3°';
      default:
        return '#$posicion';
    }
  }

  bool get hasMultipleLocales => totalLocales > 1;

  bool get hasDetailedSucursales =>
      sucursales.trim().isNotEmpty && sucursales.trim() != empresa.trim();

  factory ParetoItemModel.fromJson(Map<String, dynamic> json) {
    return ParetoItemModel(
      posicion: _toInt(json['posicion']),
      empresa: json['empresa']?.toString() ?? '',
      ruc: json['ruc']?.toString() ?? '',
      mrr: _toDouble(json['mrr'] ?? json['mrr_total']),
      totalLocales: _toInt(json['total_locales'] ?? json['locales'] ?? 1),
      sucursales: json['sucursales']?.toString() ?? '',
      participacionPct: _toDouble(json['participacion_pct'] ?? json['pct']),
      acumuladoPct: _toDouble(json['acumulado_pct']),
      esVital80: json['es_vital_80'] == true ||
          json['es_vital_80'] == 1 ||
          json['es_vital_80']?.toString() == '1' ||
          json['es_vital_80']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posicion': posicion,
      'empresa': empresa,
      'ruc': ruc,
      'mrr': mrr,
      'total_locales': totalLocales,
      'sucursales': sucursales,
      'participacion_pct': participacionPct,
      'acumulado_pct': acumuladoPct,
      'es_vital_80': esVital80,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Resumen global del análisis de Pareto para la cartera de rentas
class ParetoResumenModel {
  final double totalMrr;
  final int totalEmpresas;
  final double mrrTopTen;
  final double participacionTopTenPct;
  final List<ParetoItemModel> topTen;
  final List<ParetoItemModel> rankingCompleto;

  const ParetoResumenModel({
    required this.totalMrr,
    required this.totalEmpresas,
    required this.mrrTopTen,
    required this.participacionTopTenPct,
    required this.topTen,
    this.rankingCompleto = const [],
  });

  /// MRR correspondiente al resto de los inquilinos fuera del Top 10
  double get mrrResto => (totalMrr >= mrrTopTen) ? (totalMrr - mrrTopTen) : 0.0;

  /// % de participación del resto de inquilinos
  double get participacionRestoPct =>
      (participacionTopTenPct <= 100.0) ? (100.0 - participacionTopTenPct) : 0.0;

  /// Conteo de empresas que forman la zona vital del 80%
  int get vitalCount {
    final list = rankingCompleto.isNotEmpty ? rankingCompleto : topTen;
    return list.where((item) => item.esVital80).length;
  }

  factory ParetoResumenModel.fromJson(Map<String, dynamic> json) {
    final rawTopTen = json['top_ten'];
    final List<ParetoItemModel> parsedTopTen = [];
    if (rawTopTen is List) {
      for (final item in rawTopTen) {
        if (item is Map<String, dynamic>) {
          parsedTopTen.add(ParetoItemModel.fromJson(item));
        } else if (item is Map) {
          parsedTopTen.add(ParetoItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawRanking = json['ranking_completo'];
    final List<ParetoItemModel> parsedRanking = [];
    if (rawRanking is List) {
      for (final item in rawRanking) {
        if (item is Map<String, dynamic>) {
          parsedRanking.add(ParetoItemModel.fromJson(item));
        } else if (item is Map) {
          parsedRanking.add(ParetoItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ParetoResumenModel(
      totalMrr: ParetoItemModel._toDouble(json['total_mrr'] ?? json['total_mrr_cartera']),
      totalEmpresas: ParetoItemModel._toInt(json['total_empresas']),
      mrrTopTen: ParetoItemModel._toDouble(json['mrr_top_ten']),
      participacionTopTenPct:
          ParetoItemModel._toDouble(json['participacion_top_ten_pct']),
      topTen: parsedTopTen,
      rankingCompleto: parsedRanking.isNotEmpty ? parsedRanking : parsedTopTen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_mrr': totalMrr,
      'total_empresas': totalEmpresas,
      'mrr_top_ten': mrrTopTen,
      'participacion_top_ten_pct': participacionTopTenPct,
      'top_ten': topTen.map((e) => e.toJson()).toList(),
      'ranking_completo': rankingCompleto.map((e) => e.toJson()).toList(),
    };
  }
}
