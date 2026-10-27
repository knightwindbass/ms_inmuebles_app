/// Modelo de datos para Inversión Histórica de Proyectos y Análisis de Costos por m².
class InversionesHistoricasResponse {
  final String corteFecha;
  final InversionesResumenModel resumen;
  final List<InversionProyectoModel> proyectos;

  InversionesHistoricasResponse({
    required this.corteFecha,
    required this.resumen,
    required this.proyectos,
  });

  factory InversionesHistoricasResponse.fromJson(Map<String, dynamic> json) {
    return InversionesHistoricasResponse(
      corteFecha: json['corte_fecha'] as String? ?? '26 de octubre de 2026',
      resumen: InversionesResumenModel.fromJson(
        json['resumen'] as Map<String, dynamic>? ?? {},
      ),
      proyectos: (json['proyectos'] as List<dynamic>?)
              ?.map((e) => InversionProyectoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class InversionesResumenModel {
  final double inversionTotal;
  final double construccionTotal;
  final double terrenosTotal;
  final double financierosTotal;
  final int totalProyectos;
  final double areaBodegaTotal;

  InversionesResumenModel({
    required this.inversionTotal,
    required this.construccionTotal,
    required this.terrenosTotal,
    required this.financierosTotal,
    required this.totalProyectos,
    required this.areaBodegaTotal,
  });

  factory InversionesResumenModel.fromJson(Map<String, dynamic> json) {
    return InversionesResumenModel(
      inversionTotal: _toDouble(json['inversion_total'] ?? json['total_inversion_con_financieros'] ?? 70798999.35),
      construccionTotal: _toDouble(json['construccion_total'] ?? json['total_construccion'] ?? 58056343.79),
      terrenosTotal: _toDouble(json['terrenos_total'] ?? json['total_terreno'] ?? 10419170.62),
      financierosTotal: _toDouble(json['financieros_total'] ?? json['total_gastos_financieros'] ?? 2323484.94),
      totalProyectos: json['total_proyectos'] as int? ?? 12,
      areaBodegaTotal: _toDouble(json['area_bodega_total'] ?? 123481.13),
    );
  }

  // Porcentajes de composición
  double get pctConstruccion => inversionTotal > 0 ? (construccionTotal / inversionTotal) * 100 : 0.0;
  double get pctTerreno => inversionTotal > 0 ? (terrenosTotal / inversionTotal) * 100 : 0.0;
  double get pctFinancieros => inversionTotal > 0 ? (financierosTotal / inversionTotal) * 100 : 0.0;
}

class InversionProyectoModel {
  final int id;
  final String slugId;
  final String name;
  final String categoriaCalidad;
  final double? calificacion;
  final String periodo;
  final double terreno;
  final double construccion;
  final double? financieros;
  final bool financierosRegistrados;
  final double totalInvertido;
  final double? areaBodega;
  final double? areaPatio;
  final double? patioRatio;
  final double? costoM2Construccion;
  final double? costoM2ConTierra;
  final double? costoM2Total;
  final String nota;
  final String ciudad;
  final String inquilino;

  InversionProyectoModel({
    required this.id,
    required this.slugId,
    required this.name,
    required this.categoriaCalidad,
    this.calificacion,
    required this.periodo,
    required this.terreno,
    required this.construccion,
    this.financieros,
    required this.financierosRegistrados,
    required this.totalInvertido,
    this.areaBodega,
    this.areaPatio,
    this.patioRatio,
    this.costoM2Construccion,
    this.costoM2ConTierra,
    this.costoM2Total,
    required this.nota,
    this.ciudad = '',
    this.inquilino = '',
  });

  factory InversionProyectoModel.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['proyecto_nombre'] ?? json['nombre_proyecto'] ?? 'Sin nombre').toString();
    final terr = _toDouble(json['terreno'] ?? json['inversion_terreno']);
    final constr = _toDouble(json['construccion'] ?? json['inversion_construccion']);
    final fin = _toNullableDouble(json['financieros'] ?? json['gastos_financieros']);
    final bodega = _toNullableDouble(json['area_bodega'] ?? json['area_bodega_m2']);
    final patio = _toNullableDouble(json['area_patio'] ?? json['area_patio_m2']);
    final ratio = _toNullableDouble(json['patio_ratio']);

    final totalInv = _toDouble(json['total_invertido'] ?? json['total_con_financieros'] ?? (terr + constr + (fin ?? 0.0)));
    final cM2Const = bodega != null && bodega > 0 ? (constr / bodega) : _toNullableDouble(json['costo_m2_construccion']);
    final cM2Tierra = bodega != null && bodega > 0 ? ((constr + terr) / bodega) : _toNullableDouble(json['costo_m2_con_tierra']);
    final cM2Tot = bodega != null && bodega > 0 ? ((constr + terr + (fin ?? 0.0)) / bodega) : _toNullableDouble(json['costo_m2_total']);

    return InversionProyectoModel(
      id: json['id'] as int? ?? 0,
      slugId: (json['slug_id'] ?? '').toString(),
      name: name,
      categoriaCalidad: (json['categoria_calidad'] ?? 'Básica').toString(),
      calificacion: _toNullableDouble(json['calificacion'] ?? json['score_calidad']),
      periodo: (json['periodo'] ?? json['periodo_construccion'] ?? '').toString(),
      terreno: terr,
      construccion: constr,
      financieros: fin,
      financierosRegistrados: json['financieros_registrados'] == true || json['financieros_registrados'] == 1 || fin != null,
      totalInvertido: totalInv,
      areaBodega: bodega,
      areaPatio: patio,
      patioRatio: ratio ?? (bodega != null && patio != null && bodega > 0 ? patio / bodega : null),
      costoM2Construccion: cM2Const,
      costoM2ConTierra: cM2Tierra,
      costoM2Total: cM2Tot,
      nota: (json['nota'] ?? json['observaciones'] ?? '').toString(),
      ciudad: (json['ciudad'] ?? '').toString(),
      inquilino: (json['inquilino_principal'] ?? json['inquilino'] ?? '').toString(),
    );
  }

  // Costo por m² calculado para cualquier superficie simulada
  double? simularCostoConstruccion(double superficie) {
    if (superficie <= 0) return null;
    return construccion / superficie;
  }

  double? simularCostoConTierra(double superficie) {
    if (superficie <= 0) return null;
    return (construccion + terreno) / superficie;
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    final clean = val.replaceAll(',', '.').trim();
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}

double? _toNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) {
    if (val.trim().isEmpty) return null;
    final clean = val.replaceAll(',', '.').trim();
    return double.tryParse(clean);
  }
  return null;
}
