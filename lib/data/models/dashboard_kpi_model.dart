/// Modelo para las métricas e inteligencia de negocio (/dashboard/resumen).
class DashboardKpiModel {
  final InmueblesDesglose inmuebles;
  final JerarquiaDesglose jerarquia;
  final double tasaOcupacion;
  final double ingresosMensualesProyectados;
  final List<DistribucionTipoEstado> distribucionTiposEstado;
  final List<RentabilidadUbicacion> rentabilidadUbicacion;

  // Nuevas Métricas Inteligentes (Smart Cards) y Personalización por Tenant
  final double? rentaMensualBase;
  final double? areaTotalRentable;
  final double? areaOcupada;
  final double? areaVacante;
  final double? rentaPromedioM2;
  final double? rentaPotencialTotal;
  final String? tendenciaRentaMensual;
  final String? tendenciaRentaPromedio;
  final String? tendenciaRentaPotencial;
  final String? bannerUrl;
  final String? logoUrl;
  final String? slogan;

  static const List<String> labelsTipos = [
    'Edificio',
    'Bodega',
    'Local',
    'Oficina',
    'Terreno',
  ];

  DashboardKpiModel({
    required this.inmuebles,
    required this.jerarquia,
    required this.tasaOcupacion,
    required this.ingresosMensualesProyectados,
    required this.distribucionTiposEstado,
    this.rentabilidadUbicacion = const [],
    this.rentaMensualBase,
    this.areaTotalRentable,
    this.areaOcupada,
    this.areaVacante,
    this.rentaPromedioM2,
    this.rentaPotencialTotal,
    this.tendenciaRentaMensual,
    this.tendenciaRentaPromedio,
    this.tendenciaRentaPotencial,
    this.bannerUrl,
    this.logoUrl,
    this.slogan,
  });

  // Getters inteligentes calculados dinámicamente según la realidad del portafolio
  double get displayRentaMensual => rentaMensualBase ?? (ingresosMensualesProyectados > 0 ? ingresosMensualesProyectados : 0.0);
  double get displayTasaOcupacion => tasaOcupacion;
  double get displayAreaTotal => areaTotalRentable ?? 0.0;
  double get displayAreaOcupada => areaOcupada ?? (displayAreaTotal > 0 ? (displayAreaTotal * (displayTasaOcupacion / 100)) : 0.0);
  double get displayAreaVacante => areaVacante ?? (displayAreaTotal >= displayAreaOcupada ? (displayAreaTotal - displayAreaOcupada) : 0.0);
  double get displayRentaPromedioM2 => rentaPromedioM2 ?? (displayAreaOcupada > 0 ? (displayRentaMensual / displayAreaOcupada) : 0.0);
  double get displayRentaPotencial => rentaPotencialTotal ?? (displayRentaPromedioM2 * displayAreaTotal);
  String? get displayTendenciaRentaMensual => tendenciaRentaMensual;
  String? get displayTendenciaRentaPromedio => tendenciaRentaPromedio;
  String? get displayTendenciaRentaPotencial => tendenciaRentaPotencial;
  String get displaySlogan => slogan ?? 'ESPACIOS QUE IMPULSAN';

  DashboardKpiModel copyWith({
    InmueblesDesglose? inmuebles,
    JerarquiaDesglose? jerarquia,
    double? tasaOcupacion,
    double? ingresosMensualesProyectados,
    List<DistribucionTipoEstado>? distribucionTiposEstado,
    List<RentabilidadUbicacion>? rentabilidadUbicacion,
    double? rentaMensualBase,
    double? areaTotalRentable,
    double? areaOcupada,
    double? areaVacante,
    double? rentaPromedioM2,
    double? rentaPotencialTotal,
    String? tendenciaRentaMensual,
    String? tendenciaRentaPromedio,
    String? tendenciaRentaPotencial,
    String? bannerUrl,
    String? logoUrl,
    String? slogan,
  }) {
    return DashboardKpiModel(
      inmuebles: inmuebles ?? this.inmuebles,
      jerarquia: jerarquia ?? this.jerarquia,
      tasaOcupacion: tasaOcupacion ?? this.tasaOcupacion,
      ingresosMensualesProyectados: ingresosMensualesProyectados ?? this.ingresosMensualesProyectados,
      distribucionTiposEstado: distribucionTiposEstado ?? this.distribucionTiposEstado,
      rentabilidadUbicacion: rentabilidadUbicacion ?? this.rentabilidadUbicacion,
      rentaMensualBase: rentaMensualBase ?? this.rentaMensualBase,
      areaTotalRentable: areaTotalRentable ?? this.areaTotalRentable,
      areaOcupada: areaOcupada ?? this.areaOcupada,
      areaVacante: areaVacante ?? this.areaVacante,
      rentaPromedioM2: rentaPromedioM2 ?? this.rentaPromedioM2,
      rentaPotencialTotal: rentaPotencialTotal ?? this.rentaPotencialTotal,
      tendenciaRentaMensual: tendenciaRentaMensual ?? this.tendenciaRentaMensual,
      tendenciaRentaPromedio: tendenciaRentaPromedio ?? this.tendenciaRentaPromedio,
      tendenciaRentaPotencial: tendenciaRentaPotencial ?? this.tendenciaRentaPotencial,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      slogan: slogan ?? this.slogan,
    );
  }

  factory DashboardKpiModel.fromJson(Map<String, dynamic> rawJson) {
    // Si viene dentro de un contenedor "data" o "resumen"
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : (rawJson['resumen'] is Map<String, dynamic>
            ? rawJson['resumen'] as Map<String, dynamic>
            : rawJson);

    final inmueblesObj = InmueblesDesglose.fromJson(json['inmuebles'], json);
    final jerarquiaObj = JerarquiaDesglose.fromJson(json['jerarquia'], json);

    final rawTasa = json['tasa_ocupacion'] ?? json['ocupacion'] ?? json['tasa_ocupacion_porcentaje'];
    final rawMrr = json['ingresos_mensuales_proyectados'] ??
        json['mrr'] ??
        json['ingresos_proyectados'] ??
        json['ingresos_mensuales'];

    // Normalización de Distribución por Tipología (Lógica de Normalización Dart)
    final List<dynamic> rawDistribucion = (json['distribucion_tipos_estado'] is List)
        ? json['distribucion_tipos_estado'] as List<dynamic>
        : [];

    final List<DistribucionTipoEstado> normalizedDistribution = labelsTipos.map((tipo) {
      // Serie 1: Ocupados (estado: rentado)
      dynamic matchOcupados;
      for (final d in rawDistribucion) {
        if (d is Map &&
            d['tipo']?.toString().toLowerCase() == tipo.toLowerCase() &&
            d['estado']?.toString().toLowerCase() == 'rentado') {
          matchOcupados = d;
          break;
        }
      }
      final int ocupados = matchOcupados != null ? _toInt(matchOcupados['cantidad']) : 0;

      // Serie 2: Disponibles (estado: disponible)
      dynamic matchDisponibles;
      for (final d in rawDistribucion) {
        if (d is Map &&
            d['tipo']?.toString().toLowerCase() == tipo.toLowerCase() &&
            d['estado']?.toString().toLowerCase() == 'disponible') {
          matchDisponibles = d;
          break;
        }
      }
      final int disponibles = matchDisponibles != null ? _toInt(matchDisponibles['cantidad']) : 0;

      return DistribucionTipoEstado(
        tipo: tipo,
        libres: disponibles,
        ocupadas: ocupados,
      );
    }).toList();

    // Normalización de Rentabilidad por Ubicación
    final List<dynamic> rawRentabilidad = (json['rentabilidad_ubicacion'] is List)
        ? json['rentabilidad_ubicacion'] as List<dynamic>
        : [];
    final List<RentabilidadUbicacion> parsedRentabilidad = [];
    for (final item in rawRentabilidad) {
      if (item is Map<String, dynamic>) {
        parsedRentabilidad.add(RentabilidadUbicacion.fromJson(item));
      } else if (item is Map) {
        parsedRentabilidad.add(RentabilidadUbicacion.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return DashboardKpiModel(
      inmuebles: inmueblesObj,
      jerarquia: jerarquiaObj,
      tasaOcupacion: _toDouble(rawTasa),
      ingresosMensualesProyectados: _toDouble(rawMrr),
      distribucionTiposEstado: normalizedDistribution,
      rentabilidadUbicacion: parsedRentabilidad,
      rentaMensualBase: json['renta_mensual_base'] != null ? _toDouble(json['renta_mensual_base']) : null,
      areaTotalRentable: json['area_total_rentable'] != null ? _toDouble(json['area_total_rentable']) : null,
      areaOcupada: json['area_ocupada'] != null ? _toDouble(json['area_ocupada']) : null,
      areaVacante: json['area_vacante'] != null ? _toDouble(json['area_vacante']) : null,
      rentaPromedioM2: json['renta_promedio_m2'] != null ? _toDouble(json['renta_promedio_m2']) : null,
      rentaPotencialTotal: json['renta_potencial_total'] != null ? _toDouble(json['renta_potencial_total']) : null,
      tendenciaRentaMensual: json['tendencia_renta_mensual']?.toString(),
      tendenciaRentaPromedio: json['tendencia_renta_promedio']?.toString(),
      tendenciaRentaPotencial: json['tendencia_renta_potencial']?.toString(),
      bannerUrl: json['banner_url']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      slogan: json['slogan']?.toString(),
    );
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

class InmueblesDesglose {
  final int total;
  final int disponibles;
  final int rentados;
  final int mantenimiento;
  final int inactivo;

  InmueblesDesglose({
    this.total = 0,
    this.disponibles = 0,
    this.rentados = 0,
    this.mantenimiento = 0,
    this.inactivo = 0,
  });

  factory InmueblesDesglose.fromJson(dynamic rawJson, [Map<String, dynamic>? rootJson]) {
    if (rawJson == null && rootJson == null) return InmueblesDesglose();

    if (rawJson is num || rawJson is String) {
      final totalNum = _toInt(rawJson);
      final estados = rootJson?['estados'] ?? rootJson?['desglose'] ?? rootJson?['por_estado'];
      if (estados is Map<String, dynamic>) {
        return InmueblesDesglose.fromMap(estados, totalNum);
      }
      return InmueblesDesglose(total: totalNum);
    }

    if (rawJson is List) {
      int d = 0, r = 0, m = 0, i = 0, tot = 0;
      for (final item in rawJson) {
        if (item is Map<String, dynamic>) {
          final est = (item['estado'] ?? item['status'] ?? item['tipo'] ?? '').toString().toLowerCase();
          final cnt = _toInt(item['conteo'] ?? item['cantidad'] ?? item['total'] ?? item['count']);
          tot += cnt;
          if (est.contains('disp') || est.contains('libre')) {
            d += cnt;
          } else if (est.contains('rent') || est.contains('ocup')) {
            r += cnt;
          } else if (est.contains('mant')) {
            m += cnt;
          } else if (est.contains('inac')) {
            i += cnt;
          }
        }
      }
      return InmueblesDesglose(total: tot, disponibles: d, rentados: r, mantenimiento: m, inactivo: i);
    }

    if (rawJson is Map<String, dynamic>) {
      return InmueblesDesglose.fromMap(rawJson);
    }

    return InmueblesDesglose();
  }

  factory InmueblesDesglose.fromMap(Map<String, dynamic> json, [int? fallbackTotal]) {
    final disp = _toInt(json['disponibles'] ?? json['disponible'] ?? json['libres'] ?? json['libre'] ?? json['vacantes']);
    final rent = _toInt(json['rentados'] ?? json['rentado'] ?? json['ocupados'] ?? json['ocupado'] ?? json['arrendados'] ?? json['arrendado']);
    final mant = _toInt(json['mantenimiento'] ?? json['en_mantenimiento'] ?? json['reparacion']);
    final inac = _toInt(json['inactivo'] ?? json['inactivos'] ?? json['desactivados']);

    int tot = _toInt(json['total'] ?? json['total_inmuebles'] ?? json['conteo'] ?? json['cantidad'] ?? json['count']);
    if (tot == 0) {
      tot = fallbackTotal ?? (disp + rent + mant + inac);
    }

    return InmueblesDesglose(
      total: tot,
      disponibles: disp,
      rentados: rent,
      mantenimiento: mant,
      inactivo: inac,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Mapeo exacto de jerarquía de inmuebles (matrices vs sub-unidades)
class JerarquiaDesglose {
  final int princActivas;
  final int princInactivas;
  final int subActivas;
  final int subInactivas;

  JerarquiaDesglose({
    this.princActivas = 0,
    this.princInactivas = 0,
    this.subActivas = 0,
    this.subInactivas = 0,
  });

  int get totalPrincipales => princActivas + princInactivas;
  int get totalSubunidades => subActivas + subInactivas;

  // Propiedades de conveniencia
  int get matrices => totalPrincipales;
  int get subunidadesActivas => subActivas;
  int get subunidadesInactivas => subInactivas;

  factory JerarquiaDesglose.fromJson(dynamic rawJson, [Map<String, dynamic>? rootJson]) {
    if (rawJson == null && rootJson == null) return JerarquiaDesglose();

    if (rawJson is Map<String, dynamic>) {
      return JerarquiaDesglose.fromMap(rawJson);
    }

    return JerarquiaDesglose();
  }

  factory JerarquiaDesglose.fromMap(Map<String, dynamic> json) {
    final pAct = _toInt(
      json['princ_activas'] ??
          json['principales_activas'] ??
          json['matrices_activas'] ??
          json['matrices'] ??
          json['matriz'],
    );
    final pInac = _toInt(
      json['princ_inactivas'] ??
          json['principales_inactivas'] ??
          json['matrices_inactivas'] ??
          json['matrices_inactivo'],
    );
    final sAct = _toInt(
      json['sub_activas'] ??
          json['subunidades_activas'] ??
          json['subunidades'] ??
          json['sub_unidades'] ??
          json['hijas'],
    );
    final sInac = _toInt(
      json['sub_inactivas'] ??
          json['subunidades_inactivas'] ??
          json['sub_unidades_inactivas'] ??
          json['inactivas'],
    );

    return JerarquiaDesglose(
      princActivas: pAct,
      princInactivas: pInac,
      subActivas: sAct,
      subInactivas: sInac,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class DistribucionTipoEstado {
  final String tipo;
  final int libres; // Disponibles
  final int ocupadas; // Rentadas / Ocupadas

  DistribucionTipoEstado({
    required this.tipo,
    this.libres = 0,
    this.ocupadas = 0,
  });

  int get total => libres + ocupadas;

  factory DistribucionTipoEstado.fromJson(Map<String, dynamic> json) {
    return DistribucionTipoEstado(
      tipo: json['tipo']?.toString() ?? 'Otro',
      libres: _toInt(json['libres'] ?? json['disponibles'] ?? json['disponible']),
      ocupadas: _toInt(json['ocupadas'] ?? json['rentados'] ?? json['rentado'] ?? json['ocupados']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Modelo para el reporte de Rentabilidad Promedio por Ubicación (Complejos Rentados).
class RentabilidadUbicacion {
  final String ubicacion;
  final int cantidad;
  final double promedio;
  final double promedioM2;

  RentabilidadUbicacion({
    required this.ubicacion,
    required this.cantidad,
    required this.promedio,
    this.promedioM2 = 0.0,
  });

  factory RentabilidadUbicacion.fromJson(Map<String, dynamic> json) {
    return RentabilidadUbicacion(
      ubicacion: json['ubicacion']?.toString() ?? 'Sin ubicación',
      cantidad: _toInt(json['cantidad']),
      promedio: _toDouble(json['promedio']),
      promedioM2: _toDouble(json['promedio_m2'] ?? json['promedio_metro_cuadrado'] ?? json['valor_promedio_m2']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
