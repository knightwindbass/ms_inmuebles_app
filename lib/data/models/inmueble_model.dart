import 'dart:convert';
import 'contrato_model.dart';

/// Modelo para Inmuebles / Propiedades (/inmuebles y /inmuebles/{id}).
class InmuebleModel {
  final int id;
  final String nombre;
  final String tipo;
  final double valorRentaBase;
  final double? metraje;
  final String estado;
  final int? propiedadPadreId;
  final String? propietario;
  final String? provincia;
  final String? ciudad;
  final String? direccion;
  final String? enlaceGoogleMaps;
  final List<String> galeria;
  final List<ContratoModel> contratos;
  final List<InmuebleModel> subunidades;

  InmuebleModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.valorRentaBase,
    this.metraje,
    this.estado = 'disponible',
    this.propiedadPadreId,
    this.propietario,
    this.provincia,
    this.ciudad,
    this.direccion,
    this.enlaceGoogleMaps,
    this.galeria = const [],
    this.contratos = const [],
    this.subunidades = const [],
  });

  bool get isRentado => estado.toLowerCase() == 'rentado';
  bool get isDisponible => estado.toLowerCase() == 'disponible';
  bool get isMantenimiento => estado.toLowerCase() == 'mantenimiento';
  bool get isInactivo => estado.toLowerCase() == 'inactivo';

  bool get isMatriz => (propiedadPadreId == null || propiedadPadreId == 0) && (tipo.toLowerCase() == 'edificio' || subunidades.isNotEmpty);
  bool get isSubunidad => propiedadPadreId != null && propiedadPadreId! > 0;

  static String normalizeTipo(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Local';
    final lower = raw.trim().toLowerCase();
    if (lower.startsWith('edif')) return 'Edificio';
    if (lower.startsWith('bodeg')) return 'Bodega';
    if (lower.startsWith('loca')) return 'Local';
    if (lower.startsWith('ofic')) return 'Oficina';
    if (lower.startsWith('terr')) return 'Terreno';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  factory InmuebleModel.fromJson(Map<String, dynamic> json) {
    final rawPadreId = json['propiedad_padre_id'] ??
        json['padre_id'] ??
        json['parent_id'] ??
        json['id_padre'] ??
        (json['padre'] is Map ? json['padre']['id'] : null);

    return InmuebleModel(
      id: _toInt(json['id']),
      nombre: json['nombre']?.toString() ?? '',
      tipo: normalizeTipo(json['tipo']?.toString() ?? json['tipologia']?.toString() ?? json['tipo_inmueble']?.toString()),
      valorRentaBase: _toDouble(json['valor_renta_base'] ?? json['renta'] ?? json['precio'] ?? json['valor_renta']),
      metraje: json['metraje'] != null ? _toDouble(json['metraje']) : null,
      estado: json['estado']?.toString().toLowerCase() ?? 'disponible',
      propiedadPadreId: (rawPadreId != null && rawPadreId.toString().isNotEmpty && rawPadreId.toString() != '0')
          ? _toInt(rawPadreId)
          : null,
      propietario: json['propietario']?.toString(),
      provincia: json['provincia']?.toString(),
      ciudad: json['ciudad']?.toString(),
      direccion: json['direccion']?.toString(),
      enlaceGoogleMaps: json['enlace_google_maps']?.toString() ?? json['maps_url']?.toString(),
      galeria: _toList(json['galeria']).map((e) => e.toString()).toList(),
      contratos: _toList(json['contratos'])
          .whereType<Map<String, dynamic>>()
          .map((e) => ContratoModel.fromJson(e))
          .toList(),
      subunidades: _toList(json['subunidades'])
          .whereType<Map<String, dynamic>>()
          .map((e) => InmuebleModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'valor_renta_base': valorRentaBase,
      if (metraje != null) 'metraje': metraje,
      'estado': estado,
      if (propiedadPadreId != null) 'propiedad_padre_id': propiedadPadreId,
      if (propietario != null) 'propietario': propietario,
      if (provincia != null) 'provincia': provincia,
      if (ciudad != null) 'ciudad': ciudad,
      if (direccion != null) 'direccion': direccion,
      if (enlaceGoogleMaps != null) 'enlace_google_maps': enlaceGoogleMaps,
      if (galeria.isNotEmpty) 'galeria': galeria,
    };
  }

  static List<dynamic> _toList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '[]' || trimmed == 'null') return [];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) return decoded;
      } catch (_) {
        return [trimmed];
      }
    }
    return [];
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
