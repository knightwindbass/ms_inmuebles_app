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
  final double valorPactado;
  final String frecuenciaPago;
  final String estado;
  final String nombresInquilino;
  final String? identificacionInquilino;
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
    required this.valorPactado,
    this.frecuenciaPago = 'mensual',
    this.estado = 'vigente',
    required this.nombresInquilino,
    this.identificacionInquilino,
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

  bool get isVigente => estado.toLowerCase() == 'vigente';

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

  /// Cálculo de los días restantes hasta la fecha de fin
  int get diasRestantes {
    if (fechaFin.isEmpty) return 0;
    try {
      final target = DateTime.parse(fechaFin);
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
    double? valorPactado,
    String? frecuenciaPago,
    String? estado,
    String? nombresInquilino,
    String? identificacionInquilino,
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
      valorPactado: valorPactado ?? this.valorPactado,
      frecuenciaPago: frecuenciaPago ?? this.frecuenciaPago,
      estado: estado ?? this.estado,
      nombresInquilino: nombresInquilino ?? this.nombresInquilino,
      identificacionInquilino: identificacionInquilino ?? this.identificacionInquilino,
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

    void addInmueble(ContratoInmuebleInfo item) {
      final exists = combinedInmuebles.any((e) =>
          (e.inmuebleId != null && item.inmuebleId != null && e.inmuebleId == item.inmuebleId) ||
          (e.nombre.toLowerCase().trim() == item.nombre.toLowerCase().trim() &&
              (e.valor - item.valor).abs() < 0.01));
      if (!exists) {
        combinedInmuebles.add(item);
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

    final double newValorPactado = valorPactado + other.valorPactado;

    final double currentMetraje = metraje ?? 0.0;
    final double otherMetraje = other.metraje ?? 0.0;
    final double newMetraje = (currentMetraje + otherMetraje) > 0 ? (currentMetraje + otherMetraje) : 0.0;

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

    final String bestEstado = (isVigente || other.isVigente) ? 'vigente' : estado;

    return copyWith(
      numeroContrato: bestNumero,
      valorPactado: newValorPactado,
      metraje: newMetraje > 0 ? newMetraje : null,
      estado: bestEstado,
      nombresInquilino: bestInq,
      identificacionInquilino: bestIden,
      emailInquilino: bestEmail,
      telefonoInquilino: bestTel,
      propietario: bestProp,
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
    String inquilinoName = 'Inquilino';
    String? inqIden;
    String? inqEmail;
    String? inqTel;

    if (json['inquilino'] is String && json['inquilino'].toString().isNotEmpty) {
      inquilinoName = json['inquilino'].toString();
    } else if (json['inquilino'] is Map) {
      inquilinoName = json['inquilino']['nombres_razon_social']?.toString() ??
          json['inquilino']['nombre']?.toString() ??
          'Inquilino';
      inqIden = json['inquilino']['identificacion']?.toString();
      inqEmail = json['inquilino']['email']?.toString();
      inqTel = json['inquilino']['telefono']?.toString();
    } else if (json['nombres_inquilino'] != null) {
      inquilinoName = json['nombres_inquilino'].toString();
    }

    inqIden ??= json['identificacion_inquilino']?.toString() ?? json['identificacion']?.toString();
    inqEmail ??= json['email_inquilino']?.toString();
    inqTel ??= json['telefono_inquilino']?.toString();

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
    final parsedNumero = json['numero_contrato']?.toString() ?? json['referencia']?.toString() ?? json['codigo']?.toString();
    final parsedMonto = _toDouble(json['valor_pactado'] ?? json['monto'] ?? json['canon'] ?? json['renta']);
    final parsedMetraje = json['metraje'] != null ? _toDouble(json['metraje']) : null;
    final parsedInmuebleId = json['inmueble_id'] != null ? _toInt(json['inmueble_id']) : null;

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

    return ContratoModel(
      id: parsedId,
      numeroContrato: parsedNumero,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      valorPactado: parsedMonto,
      frecuenciaPago: json['frecuencia_pago']?.toString().toLowerCase() ?? 'mensual',
      estado: json['estado']?.toString().toLowerCase() ?? 'vigente',
      nombresInquilino: inquilinoName,
      identificacionInquilino: inqIden,
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
      'valor_pactado': valorPactado,
      'frecuencia_pago': frecuenciaPago,
      'estado': estado,
      'inquilino': nombresInquilino,
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
