/// Modelo para Contratos de Arrendamiento (/contratos).
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
  });

  bool get isVigente => estado.toLowerCase() == 'vigente';

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

    return ContratoModel(
      id: _toInt(json['id']),
      numeroContrato: json['numero_contrato']?.toString() ?? json['referencia']?.toString(),
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      valorPactado: _toDouble(json['valor_pactado'] ?? json['monto']),
      frecuenciaPago: json['frecuencia_pago']?.toString().toLowerCase() ?? 'mensual',
      estado: json['estado']?.toString().toLowerCase() ?? 'vigente',
      nombresInquilino: inquilinoName,
      identificacionInquilino: inqIden,
      inmuebleNombre: inmName,
      inmuebleId: json['inmueble_id'] != null ? _toInt(json['inmueble_id']) : null,
      metraje: json['metraje'] != null ? _toDouble(json['metraje']) : null,
      propietario: json['propietario']?.toString(),
      emailInquilino: inqEmail,
      telefonoInquilino: inqTel,
      observaciones: json['observaciones']?.toString(),
      diaPagoPreferido: _toInt(json['dia_pago_preferido'] ?? 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
