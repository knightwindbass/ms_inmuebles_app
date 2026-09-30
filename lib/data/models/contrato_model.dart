/// Representa una unidad o inmueble asociado a un contrato de arrendamiento.
class ContratoInmuebleInfo {
  final int? inmuebleId;
  final String nombre;
  final double valor;
  final double metraje;
  final String? propietario;

  ContratoInmuebleInfo({
    this.inmuebleId,
    required this.nombre,
    this.valor = 0.0,
    this.metraje = 0.0,
    this.propietario,
  });

  factory ContratoInmuebleInfo.fromJson(Map<String, dynamic> json) {
    return ContratoInmuebleInfo(
      inmuebleId: json['id'] != null
          ? _toInt(json['id'])
          : (json['inmueble_id'] != null ? _toInt(json['inmueble_id']) : null),
      nombre: json['nombre']?.toString() ??
          json['inmueble_nombre']?.toString() ??
          json['inmueble']?.toString() ??
          'Inmueble',
      valor: _toDouble(json['valor_pactado'] ?? json['monto'] ?? json['renta'] ?? json['valor_renta']),
      metraje: _toDouble(json['metraje'] ?? json['area']),
      propietario: json['propietario']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (inmuebleId != null) 'inmueble_id': inmuebleId,
      'nombre': nombre,
      'valor': valor,
      'metraje': metraje,
      if (propietario != null) 'propietario': propietario,
    };
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

/// Modelo para Contratos de Arrendamiento (/contratos) con consolidación de propiedades por ID/referencia.
class ContratoModel {
  final int id;
  final String? numeroContrato;
  final String fechaInicio;
  final String fechaFin;
  final String? fechaFinReal;
  final bool isAutoProjected;
  final double valorPactado;
  final String frecuenciaPago;
  final String estado;
  final String nombresInquilino;
  final String? identificacionInquilino;
  final int? inquilinoId;
  final String? inmuebleNombre;
  final int? inmuebleId;
  final double? metraje;
  final String? propietario;
  final String? emailInquilino;
  final String? telefonoInquilino;
  final String? observaciones;
  final int diaPagoPreferido;
  final List<ContratoInmuebleInfo> inmueblesAsociados;

  ContratoModel({
    required this.id,
    this.numeroContrato,
    required this.fechaInicio,
    required this.fechaFin,
    this.fechaFinReal,
    this.isAutoProjected = false,
    required this.valorPactado,
    this.frecuenciaPago = 'mensual',
    this.estado = 'vigente',
    required this.nombresInquilino,
    this.identificacionInquilino,
    this.inquilinoId,
    this.inmuebleNombre,
    this.inmuebleId,
    this.metraje,
    this.propietario,
    this.emailInquilino,
    this.telefonoInquilino,
    this.observaciones,
    this.diaPagoPreferido = 1,
    this.inmueblesAsociados = const [],
  });

  bool get isVigente {
    final clean = estado.trim().toLowerCase();
    return clean == 'vigente' || clean == 'activo' || clean == 'activa';
  }

  /// Indica si el contrato ha concluido o expirado acorde a su fecha efectiva o estado
  bool get isExpirado {
    final clean = estado.trim().toLowerCase();
    if (clean == 'expirado' || clean == 'concluido' || clean == 'finalizado' || clean == 'terminado') {
      return true;
    }
    return diasRestantes <= 0;
  }

  /// Cantidad de unidades o inmuebles bajo este contrato
  int get cantidadInmuebles => inmueblesAsociados.isNotEmpty
      ? inmueblesAsociados.length
      : ((inmuebleNombre != null && inmuebleNombre!.isNotEmpty) || inmuebleId != null ? 1 : 0);

  /// Indica si el contrato abarca múltiples propiedades (bodegas, locales, etc.)
  bool get tieneMultiplesInmuebles => cantidadInmuebles > 1;

  /// Resumen formateado de los inmuebles asociados
  String get resumenInmuebles {
    if (inmueblesAsociados.length > 1) {
      return inmueblesAsociados.map((e) => e.nombre).join(' • ');
    }
    return inmuebleNombre ?? (inmuebleId != null ? 'Inmueble #$inmuebleId' : 'Sin inmueble');
  }

  /// Cálculo del metraje total acumulado de las propiedades
  double get totalMetraje {
    if (inmueblesAsociados.isNotEmpty) {
      final sum = inmueblesAsociados.fold(0.0, (acc, item) => acc + item.metraje);
      if (sum > 0) return sum;
    }
    return metraje ?? 0.0;
  }

  /// Alias de metraje total para compatibilidad
  double get metrajeTotal => totalMetraje;

  /// Fecha efectiva de fin del contrato (usa fechaFinReal si está disponible por renovación automática)
  String get fechaFinEffective =>
      (fechaFinReal != null && fechaFinReal!.trim().isNotEmpty) ? fechaFinReal!.trim() : fechaFin;

  /// Años continuos de antigüedad del inquilino desde fechaInicio
  int get aniosAntiguedad {
    if (fechaInicio.isEmpty) return 0;
    try {
      final start = DateTime.parse(fechaInicio);
      final now = DateTime.now();
      if (start.isBefore(now)) {
        return (now.difference(start).inDays / 365).floor();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Cálculo de los días restantes hasta la fecha de fin (priorizando fechaFinReal)
  int get diasRestantes {
    final effective = fechaFinEffective;
    if (effective.isEmpty) return 0;
    try {
      final target = DateTime.parse(effective);
      final now = DateTime.now();
      return target.difference(DateTime(now.year, now.month, now.day)).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Valor mensualizado (MRR) normalizando pagos anuales
  double get valorMensualizado {
    if (frecuenciaPago.toLowerCase() == 'anual') {
      return valorPactado / 12;
    }
    return valorPactado;
  }

  ContratoModel copyWith({
    int? id,
    String? numeroContrato,
    String? fechaInicio,
    String? fechaFin,
    String? fechaFinReal,
    bool? isAutoProjected,
    double? valorPactado,
    String? frecuenciaPago,
    String? estado,
    String? nombresInquilino,
    String? identificacionInquilino,
    int? inquilinoId,
    String? inmuebleNombre,
    int? inmuebleId,
    double? metraje,
    String? propietario,
    String? emailInquilino,
    String? telefonoInquilino,
    String? observaciones,
    int? diaPagoPreferido,
    List<ContratoInmuebleInfo>? inmueblesAsociados,
  }) {
    final listInm = inmueblesAsociados ?? this.inmueblesAsociados;
    String? effectiveInmuebleNombre = inmuebleNombre ?? this.inmuebleNombre;
    if (effectiveInmuebleNombre == null && listInm.isNotEmpty) {
      effectiveInmuebleNombre = listInm.length > 1
          ? listInm.map((e) => e.nombre).join(' • ')
          : listInm.first.nombre;
    }

    return ContratoModel(
      id: id ?? this.id,
      numeroContrato: numeroContrato ?? this.numeroContrato,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fechaFinReal: fechaFinReal ?? this.fechaFinReal,
      isAutoProjected: isAutoProjected ?? this.isAutoProjected,
      valorPactado: valorPactado ?? this.valorPactado,
      frecuenciaPago: frecuenciaPago ?? this.frecuenciaPago,
      estado: estado ?? this.estado,
      nombresInquilino: nombresInquilino ?? this.nombresInquilino,
      identificacionInquilino: identificacionInquilino ?? this.identificacionInquilino,
      inquilinoId: inquilinoId ?? this.inquilinoId,
      inmuebleNombre: effectiveInmuebleNombre,
      inmuebleId: inmuebleId ?? this.inmuebleId,
      metraje: metraje ?? this.metraje,
      propietario: propietario ?? this.propietario,
      emailInquilino: emailInquilino ?? this.emailInquilino,
      telefonoInquilino: telefonoInquilino ?? this.telefonoInquilino,
      observaciones: observaciones ?? this.observaciones,
      diaPagoPreferido: diaPagoPreferido ?? this.diaPagoPreferido,
      inmueblesAsociados: listInm,
    );
  }

  /// Fusiona dos registros del mismo contrato sumando cánones y agrupando inmuebles
  ContratoModel mergeWith(ContratoModel other) {
    final List<ContratoInmuebleInfo> combinedInmuebles = List.from(inmueblesAsociados);
    bool addedAnyNew = false;

    void addInmueble(ContratoInmuebleInfo item) {
      final exists = combinedInmuebles.any((e) =>
          (e.inmuebleId != null && item.inmuebleId != null && e.inmuebleId == item.inmuebleId) ||
          (e.nombre.toLowerCase().trim() == item.nombre.toLowerCase().trim() &&
              (e.valor - item.valor).abs() < 0.01));
      if (!exists) {
        combinedInmuebles.add(item);
        addedAnyNew = true;
      }
    }

    if (other.inmueblesAsociados.isNotEmpty) {
      for (final inmob in other.inmueblesAsociados) {
        addInmueble(inmob);
      }
    } else if (other.inmuebleNombre != null || other.inmuebleId != null) {
      addInmueble(ContratoInmuebleInfo(
        inmuebleId: other.inmuebleId,
        nombre: other.inmuebleNombre ?? 'Inmueble #${other.inmuebleId ?? ''}',
        valor: other.valorPactado,
        metraje: other.metraje ?? 0.0,
        propietario: other.propietario,
      ));
    }

    final double sumInmueblesValor = combinedInmuebles.fold(0.0, (acc, item) => acc + item.valor);
    final double newValorPactado = sumInmueblesValor > 0
        ? sumInmueblesValor
        : (!addedAnyNew
            ? (valorPactado > 0 ? valorPactado : other.valorPactado)
            : (valorPactado + other.valorPactado));

    final double currentMetraje = metraje ?? 0.0;
    final double otherMetraje = other.metraje ?? 0.0;
    final double sumInmMetraje = combinedInmuebles.fold(0.0, (acc, item) => acc + item.metraje);
    final double newMetraje = sumInmMetraje > 0
        ? sumInmMetraje
        : ((currentMetraje + otherMetraje) > 0 ? (currentMetraje + otherMetraje) : 0.0);

    final String? bestNumero = (numeroContrato != null && numeroContrato!.isNotEmpty)
        ? numeroContrato
        : other.numeroContrato;

    final String bestInq = nombresInquilino.isNotEmpty && nombresInquilino != 'Inquilino'
        ? nombresInquilino
        : (other.nombresInquilino.isNotEmpty ? other.nombresInquilino : nombresInquilino);

    final String? bestIden = (identificacionInquilino != null && identificacionInquilino!.isNotEmpty)
        ? identificacionInquilino
        : other.identificacionInquilino;

    final String? bestEmail = (emailInquilino != null && emailInquilino!.isNotEmpty)
        ? emailInquilino
        : other.emailInquilino;

    final String? bestTel = (telefonoInquilino != null && telefonoInquilino!.isNotEmpty)
        ? telefonoInquilino
        : other.telefonoInquilino;

    final String? bestProp = (propietario != null && propietario!.isNotEmpty)
        ? propietario
        : other.propietario;

    final int? bestInqId = (inquilinoId != null && inquilinoId != 0)
        ? inquilinoId
        : other.inquilinoId;

    final String bestEstado = (isVigente || other.isVigente) ? 'vigente' : estado;

    final String? bestFechaFinReal = (fechaFinReal != null && fechaFinReal!.isNotEmpty)
        ? fechaFinReal
        : other.fechaFinReal;
    final bool bestIsAutoProjected = isAutoProjected || other.isAutoProjected;

    return copyWith(
      numeroContrato: bestNumero,
      valorPactado: newValorPactado,
      metraje: newMetraje > 0 ? newMetraje : null,
      estado: bestEstado,
      nombresInquilino: bestInq,
      identificacionInquilino: bestIden,
      inquilinoId: bestInqId,
      emailInquilino: bestEmail,
      telefonoInquilino: bestTel,
      propietario: bestProp,
      fechaFinReal: bestFechaFinReal,
      isAutoProjected: bestIsAutoProjected,
      inmueblesAsociados: combinedInmuebles,
    );
  }

  /// Agrupa una lista de contratos consolidando por ID y número/referencia de contrato
  static List<ContratoModel> groupContratos(List<ContratoModel> rawList) {
    if (rawList.isEmpty) return [];

    final List<ContratoModel> result = [];
    final Map<String, int> indexByKey = {};

    for (final rawItem in rawList) {
      final item = rawItem.inmueblesAsociados.isNotEmpty
          ? rawItem
          : ((rawItem.inmuebleNombre != null || rawItem.inmuebleId != null)
              ? rawItem.copyWith(
                  inmueblesAsociados: [
                    ContratoInmuebleInfo(
                      inmuebleId: rawItem.inmuebleId,
                      nombre: rawItem.inmuebleNombre ?? 'Inmueble #${rawItem.inmuebleId ?? ''}',
                      valor: rawItem.valorPactado,
                      metraje: rawItem.metraje ?? 0.0,
                      propietario: rawItem.propietario,
                    ),
                  ],
                )
              : rawItem);

      final String? idKey = item.id > 0 ? 'id_${item.id}' : null;
      final String? refKey = (item.numeroContrato != null && item.numeroContrato!.trim().isNotEmpty)
          ? 'ref_${item.numeroContrato!.trim().toLowerCase()}'
          : null;

      int? existingIndex;
      if (idKey != null && indexByKey.containsKey(idKey)) {
        existingIndex = indexByKey[idKey];
      } else if (refKey != null && indexByKey.containsKey(refKey)) {
        existingIndex = indexByKey[refKey];
      }

      if (existingIndex != null) {
        result[existingIndex] = result[existingIndex].mergeWith(item);
        if (idKey != null) indexByKey[idKey] = existingIndex;
        if (refKey != null) indexByKey[refKey] = existingIndex;
      } else {
        final newIndex = result.length;
        result.add(item);
        if (idKey != null) indexByKey[idKey] = newIndex;
        if (refKey != null) indexByKey[refKey] = newIndex;
      }
    }

    return result;
  }

  factory ContratoModel.fromJson(Map<String, dynamic> json) {
    // Inquilino puede venir como String simple o como Map
    String inquilinoName = '';
    String? inqIden;
    String? inqEmail;
    String? inqTel;

    bool isValidTenantName(String? name) {
      if (name == null) return false;
      final t = name.trim();
      if (t.isEmpty || t.toLowerCase() == 'inquilino' || t.toLowerCase() == 'null' || t.toLowerCase() == 'undefined') {
        return false;
      }
      if (int.tryParse(t) != null) return false;
      return true;
    }

    if (json['inquilino'] is Map) {
      final inqMap = json['inquilino'] as Map;
      final cand = inqMap['nombres_razon_social']?.toString() ??
          inqMap['razon_social']?.toString() ??
          inqMap['nombre']?.toString() ??
          inqMap['nombre_completo']?.toString() ??
          inqMap['display_name']?.toString() ??
          inqMap['name']?.toString() ??
          inqMap['nombres']?.toString();
      if (isValidTenantName(cand)) {
        inquilinoName = cand!.trim();
      }
      inqIden = inqMap['identificacion']?.toString() ?? inqMap['cedula']?.toString() ?? inqMap['ruc']?.toString();
      inqEmail = inqMap['email']?.toString() ?? inqMap['correo']?.toString();
      inqTel = inqMap['telefono']?.toString() ?? inqMap['celular']?.toString();
    } else if (json['inquilino'] is String && isValidTenantName(json['inquilino'].toString())) {
      inquilinoName = json['inquilino'].toString().trim();
    }

    if (!isValidTenantName(inquilinoName)) {
      final candidates = [
        json['nombres_inquilino'],
        json['inquilino_nombre'],
        json['nombre_inquilino'],
        json['inquilino_nombres'],
        json['inquilino_razon_social'],
        json['razon_social'],
        json['cliente_nombre'],
        json['nombre_cliente'],
        json['arrendatario_nombre'],
        json['arrendatario_razon_social'],
        json['empresa'],
      ];
      for (final c in candidates) {
        if (isValidTenantName(c?.toString())) {
          inquilinoName = c!.toString().trim();
          break;
        }
      }
    }

    if (!isValidTenantName(inquilinoName)) {
      if (json['cliente'] is Map) {
        final clMap = json['cliente'] as Map;
        final cand = clMap['nombres_razon_social']?.toString() ??
            clMap['razon_social']?.toString() ??
            clMap['nombre']?.toString() ??
            clMap['display_name']?.toString();
        if (isValidTenantName(cand)) inquilinoName = cand!.trim();
        inqIden ??= clMap['identificacion']?.toString() ?? clMap['cedula']?.toString() ?? clMap['ruc']?.toString();
        inqEmail ??= clMap['email']?.toString() ?? clMap['correo']?.toString();
        inqTel ??= clMap['telefono']?.toString() ?? clMap['celular']?.toString();
      } else if (json['cliente'] is String && isValidTenantName(json['cliente'].toString())) {
        inquilinoName = json['cliente'].toString().trim();
      }
    }

    if (!isValidTenantName(inquilinoName)) {
      if (json['arrendatario'] is Map) {
        final arrMap = json['arrendatario'] as Map;
        final cand = arrMap['nombres_razon_social']?.toString() ??
            arrMap['razon_social']?.toString() ??
            arrMap['nombre']?.toString() ??
            arrMap['display_name']?.toString();
        if (isValidTenantName(cand)) inquilinoName = cand!.trim();
        inqIden ??= arrMap['identificacion']?.toString() ?? arrMap['cedula']?.toString() ?? arrMap['ruc']?.toString();
        inqEmail ??= arrMap['email']?.toString() ?? arrMap['correo']?.toString();
        inqTel ??= arrMap['telefono']?.toString() ?? arrMap['celular']?.toString();
      } else if (json['arrendatario'] is String && isValidTenantName(json['arrendatario'].toString())) {
        inquilinoName = json['arrendatario'].toString().trim();
      }
    }

    if (inquilinoName.isEmpty) {
      inquilinoName = 'Inquilino';
    }

    inqIden ??= json['identificacion_inquilino']?.toString() ??
        json['identificacion']?.toString() ??
        json['cedula']?.toString() ??
        json['ruc']?.toString();
    inqEmail ??= json['email_inquilino']?.toString() ?? json['email']?.toString();
    inqTel ??= json['telefono_inquilino']?.toString() ?? json['telefono']?.toString();

    // Inmueble nombre
    String? inmName;
    if (json['inmueble_nombre'] != null) {
      inmName = json['inmueble_nombre'].toString();
    } else if (json['inmueble'] is Map) {
      inmName = json['inmueble']['nombre']?.toString();
    } else if (json['inmueble'] is String) {
      inmName = json['inmueble'].toString();
    }

    final parsedId = _toInt(json['id'] ?? json['id_contrato'] ?? json['contrato_id']);
    final parsedNumero = json['numero_contrato']?.toString() ??
        json['referencia']?.toString() ??
        json['codigo']?.toString() ??
        json['numero']?.toString() ??
        json['num_contrato']?.toString() ??
        json['contrato_numero']?.toString() ??
        json['contrato_ref']?.toString() ??
        json['cod_contrato']?.toString() ??
        json['ref']?.toString() ??
        json['secuencial']?.toString() ??
        json['nro_contrato']?.toString() ??
        json['nro']?.toString() ??
        json['codigo_contrato']?.toString();
    final parsedMonto = _toDouble(json['valor_pactado'] ?? json['monto'] ?? json['canon'] ?? json['renta']);
    final parsedMetraje = json['metraje'] != null ? _toDouble(json['metraje']) : null;
    final parsedInmuebleId = json['inmueble_id'] != null ? _toInt(json['inmueble_id']) : null;
    int? parsedInquilinoId;
    if (json['inquilino_id'] != null) {
      parsedInquilinoId = _toInt(json['inquilino_id']);
    } else if (json['id_inquilino'] != null) {
      parsedInquilinoId = _toInt(json['id_inquilino']);
    } else if (json['inquilino'] is num) {
      parsedInquilinoId = (json['inquilino'] as num).toInt();
    } else if (json['inquilino'] is String && int.tryParse(json['inquilino'].toString()) != null) {
      parsedInquilinoId = int.tryParse(json['inquilino'].toString());
    } else if (json['inquilino'] is Map && json['inquilino']['id'] != null) {
      parsedInquilinoId = _toInt(json['inquilino']['id']);
    } else if (json['cliente_id'] != null) {
      parsedInquilinoId = _toInt(json['cliente_id']);
    }

    final List<ContratoInmuebleInfo> itemsAsociados = [];
    final rawInmuebles = json['inmuebles'] ?? json['propiedades'] ?? json['unidades'];
    if (rawInmuebles is List) {
      for (final raw in rawInmuebles) {
        if (raw is Map) {
          itemsAsociados.add(ContratoInmuebleInfo.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    if (itemsAsociados.isEmpty && (inmName != null || parsedInmuebleId != null)) {
      itemsAsociados.add(
        ContratoInmuebleInfo(
          inmuebleId: parsedInmuebleId,
          nombre: inmName ?? 'Inmueble #$parsedInmuebleId',
          valor: parsedMonto,
          metraje: parsedMetraje ?? 0.0,
          propietario: json['propietario']?.toString(),
        ),
      );
    }

    final bool isAutoProjected = json['is_auto_projected'] == true ||
        json['is_auto_projected'] == 1 ||
        json['is_auto_projected']?.toString().toLowerCase() == 'true';
    final String? fechaFinReal = json['fecha_fin_real']?.toString();

    return ContratoModel(
      id: parsedId,
      numeroContrato: parsedNumero,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      fechaFinReal: fechaFinReal,
      isAutoProjected: isAutoProjected,
      valorPactado: parsedMonto,
      frecuenciaPago: json['frecuencia_pago']?.toString().toLowerCase() ?? 'mensual',
      estado: json['estado']?.toString().toLowerCase() ?? 'vigente',
      nombresInquilino: inquilinoName,
      identificacionInquilino: inqIden,
      inquilinoId: parsedInquilinoId,
      inmuebleNombre: inmName,
      inmuebleId: parsedInmuebleId,
      metraje: parsedMetraje,
      propietario: json['propietario']?.toString(),
      emailInquilino: inqEmail,
      telefonoInquilino: inqTel,
      observaciones: json['observaciones']?.toString(),
      diaPagoPreferido: _toInt(json['dia_pago_preferido'] ?? 1),
      inmueblesAsociados: itemsAsociados,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_contrato': numeroContrato,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      if (fechaFinReal != null) 'fecha_fin_real': fechaFinReal,
      'is_auto_projected': isAutoProjected,
      'valor_pactado': valorPactado,
      'frecuencia_pago': frecuenciaPago,
      'estado': estado,
      'inquilino': nombresInquilino,
      if (inquilinoId != null) 'inquilino_id': inquilinoId,
      if (inmuebleNombre != null) 'inmueble_nombre': inmuebleNombre,
      if (inmuebleId != null) 'inmueble_id': inmuebleId,
      if (metraje != null) 'metraje': metraje,
      if (propietario != null) 'propietario': propietario,
      if (identificacionInquilino != null) 'identificacion_inquilino': identificacionInquilino,
      if (emailInquilino != null) 'email_inquilino': emailInquilino,
      if (telefonoInquilino != null) 'telefono_inquilino': telefonoInquilino,
      if (observaciones != null) 'observaciones': observaciones,
      'inmuebles': inmueblesAsociados.map((e) => e.toJson()).toList(),
    };
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
