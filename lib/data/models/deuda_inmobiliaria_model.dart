/// Modelo de datos para Pasivos y Riesgos Inmobiliarios (Cuadro de Deuda Consolidada).
class DeudaDashboardModel {
  final String corteFecha;
  final DeudaResumenModel resumen;
  final List<BancoDistribucionModel> distribucionBancos;
  final List<ProyectoDeudaModel> proyectos;

  DeudaDashboardModel({
    required this.corteFecha,
    required this.resumen,
    required this.distribucionBancos,
    required this.proyectos,
  });

  factory DeudaDashboardModel.fromJson(Map<String, dynamic> json) {
    return DeudaDashboardModel(
      corteFecha: json['corte_fecha'] as String? ?? '30 de septiembre de 2026',
      resumen: DeudaResumenModel.fromJson(json['resumen'] as Map<String, dynamic>? ?? {}),
      distribucionBancos: (json['distribucion_bancos'] as List<dynamic>?)
              ?.map((e) => BancoDistribucionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      proyectos: (json['proyectos'] as List<dynamic>?)
              ?.map((e) => ProyectoDeudaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DeudaResumenModel {
  final double deudaTotalConsolidada;
  final double montoOriginalRegistrado;
  final double reduccionNetaCapital;
  final double porcentajeReduccionTotal;
  final double pagoMensualRegistrado;
  final double pagoAnualizado;
  final int totalProyectos;
  final double rentasMensualesVigentes;
  final double flujoNetoMensual;
  final double? coberturaDscr;

  DeudaResumenModel({
    required this.deudaTotalConsolidada,
    required this.montoOriginalRegistrado,
    required this.reduccionNetaCapital,
    required this.porcentajeReduccionTotal,
    required this.pagoMensualRegistrado,
    required this.pagoAnualizado,
    required this.totalProyectos,
    required this.rentasMensualesVigentes,
    required this.flujoNetoMensual,
    this.coberturaDscr,
  });

  factory DeudaResumenModel.fromJson(Map<String, dynamic> json) {
    return DeudaResumenModel(
      deudaTotalConsolidada: _toDouble(json['deuda_total_consolidada']),
      montoOriginalRegistrado: _toDouble(json['monto_original_registrado']),
      reduccionNetaCapital: _toDouble(json['reduccion_neta_capital']),
      porcentajeReduccionTotal: _toDouble(json['porcentaje_reduccion_total']),
      pagoMensualRegistrado: _toDouble(json['pago_mensual_registrado']),
      pagoAnualizado: _toDouble(json['pago_anualizado']),
      totalProyectos: json['total_proyectos'] as int? ?? 0,
      rentasMensualesVigentes: _toDouble(json['rentas_mensuales_vigentes']),
      flujoNetoMensual: _toDouble(json['flujo_neto_mensual']),
      coberturaDscr: json['cobertura_dscr'] != null ? _toDouble(json['cobertura_dscr']) : null,
    );
  }
}

class BancoDistribucionModel {
  final String banco;
  final double saldo;
  final double porcentaje;

  BancoDistribucionModel({
    required this.banco,
    required this.saldo,
    required this.porcentaje,
  });

  factory BancoDistribucionModel.fromJson(Map<String, dynamic> json) {
    return BancoDistribucionModel(
      banco: json['banco'] as String? ?? '',
      saldo: _toDouble(json['saldo']),
      porcentaje: _toDouble(json['porcentaje']),
    );
  }
}

class ProyectoDeudaModel {
  final int id;
  final String slugId;
  final String name;
  final String bank;
  final double original;
  final double balance;
  final double? monthly;
  final String start;
  final String end;
  final String rate;
  final int? paid;
  final int? total;
  final String note;
  final double capitalReducido;
  final double porcentajeReducido;
  final String tipoAmortizacion;
  final List<TramoDeudaModel>? parts;

  ProyectoDeudaModel({
    required this.id,
    required this.slugId,
    required this.name,
    required this.bank,
    required this.original,
    required this.balance,
    this.monthly,
    required this.start,
    required this.end,
    required this.rate,
    this.paid,
    this.total,
    required this.note,
    required this.capitalReducido,
    required this.porcentajeReducido,
    required this.tipoAmortizacion,
    this.parts,
  });

  factory ProyectoDeudaModel.fromJson(Map<String, dynamic> json) {
    return ProyectoDeudaModel(
      id: json['id'] as int? ?? 0,
      slugId: json['slug_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bank: json['bank'] as String? ?? '',
      original: _toDouble(json['original']),
      balance: _toDouble(json['balance']),
      monthly: json['monthly'] != null ? _toDouble(json['monthly']) : null,
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      rate: json['rate'] as String? ?? '',
      paid: json['paid'] as int?,
      total: json['total'] as int?,
      note: json['note'] as String? ?? '',
      capitalReducido: _toDouble(json['capital_reducido']),
      porcentajeReducido: _toDouble(json['porcentaje_reducido']),
      tipoAmortizacion: json['tipo_amortizacion'] as String? ?? 'frances',
      parts: (json['parts'] as List<dynamic>?)
          ?.map((e) => TramoDeudaModel.fromJson(e))
          .toList(),
    );
  }
}

class TramoDeudaModel {
  final int? id;
  final String descripcion;
  final String banco;
  final double monto;
  final double? cuota;
  final String inicio;
  final String fin;
  final int? pagadas;
  final int? total;
  final String tasa;
  final String tipoPago;

  TramoDeudaModel({
    this.id,
    required this.descripcion,
    required this.banco,
    required this.monto,
    this.cuota,
    required this.inicio,
    required this.fin,
    this.pagadas,
    this.total,
    this.tasa = '',
    this.tipoPago = 'capital_interes',
  });

  factory TramoDeudaModel.fromJson(dynamic data) {
    if (data is List) {
      // Formato tupla directa del prototipo React ChatGPT: [desc, monto, cuota, inicio, fin, pagadas, total]
      return TramoDeudaModel(
        descripcion: data.isNotEmpty ? (data[0]?.toString() ?? '') : '',
        banco: '',
        monto: data.length > 1 ? _toDouble(data[1]) : 0.0,
        cuota: data.length > 2 && data[2] != null ? _toDouble(data[2]) : null,
        inicio: data.length > 3 ? (data[3]?.toString() ?? '') : '',
        fin: data.length > 4 ? (data[4]?.toString() ?? '') : '',
        pagadas: data.length > 5 && data[5] != null ? int.tryParse(data[5].toString()) : null,
        total: data.length > 6 && data[6] != null ? int.tryParse(data[6].toString()) : null,
      );
    }

    final map = data as Map<String, dynamic>;
    return TramoDeudaModel(
      id: map['id'] as int?,
      descripcion: map['descripcion'] as String? ?? '',
      banco: map['banco'] as String? ?? '',
      monto: _toDouble(map['monto'] ?? map['monto_original']),
      cuota: map['cuota'] != null ? _toDouble(map['cuota']) : (map['cuota_mensual'] != null ? _toDouble(map['cuota_mensual']) : null),
      inicio: map['inicio'] as String? ?? (map['fecha_inicio'] as String? ?? ''),
      fin: map['fin'] as String? ?? (map['fecha_vencimiento'] as String? ?? ''),
      pagadas: map['pagadas'] as int? ?? (map['cuotas_pagadas'] as int?),
      total: map['total'] as int? ?? (map['total_cuotas'] as int?),
      tasa: map['tasa'] as String? ?? (map['tasa_interes'] as String? ?? ''),
      tipoPago: map['tipo_pago'] as String? ?? 'capital_interes',
    );
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? 0.0;
  }
  return 0.0;
}
