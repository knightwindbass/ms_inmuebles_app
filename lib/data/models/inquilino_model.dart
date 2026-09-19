/// Modelo para Inquilinos / Directorio de Clientes (/inquilinos).
class InquilinoModel {
  final int id;
  final String? tenantId;
  final String identificacion;
  final String nombresRazonSocial;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String? logo;
  final int contratosVigentes;

  InquilinoModel({
    required this.id,
    this.tenantId,
    required this.identificacion,
    required this.nombresRazonSocial,
    this.email,
    this.telefono,
    this.direccion,
    this.logo,
    this.contratosVigentes = 0,
  });

  bool get isActivo => contratosVigentes > 0;

  factory InquilinoModel.fromJson(Map<String, dynamic> json) {
    final rawEmail = json['email']?.toString();
    final rawTel = json['telefono']?.toString();
    final rawDir = json['direccion']?.toString();
    final rawLogo = json['logo']?.toString() ?? json['logo_url']?.toString();

    return InquilinoModel(
      id: _toInt(json['id']),
      tenantId: json['tenant_id']?.toString(),
      identificacion: json['identificacion']?.toString() ?? json['cedula']?.toString() ?? json['ruc']?.toString() ?? '',
      nombresRazonSocial: json['nombres_razon_social']?.toString() ?? json['nombre']?.toString() ?? json['razon_social']?.toString() ?? 'Inquilino',
      email: (rawEmail != null && rawEmail.trim().isNotEmpty) ? rawEmail.trim() : null,
      telefono: (rawTel != null && rawTel.trim().isNotEmpty) ? rawTel.trim() : null,
      direccion: (rawDir != null && rawDir.trim().isNotEmpty) ? rawDir.trim() : null,
      logo: (rawLogo != null && rawLogo.trim().isNotEmpty) ? rawLogo.trim() : null,
      contratosVigentes: _toInt(json['contratos_vigentes'] ?? json['contratos_activos'] ?? json['vigentes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identificacion': identificacion,
      'nombres_razon_social': nombresRazonSocial,
      if (tenantId != null) 'tenant_id': tenantId,
      if (email != null) 'email': email,
      if (telefono != null) 'telefono': telefono,
      if (direccion != null) 'direccion': direccion,
      if (logo != null) 'logo': logo,
      'contratos_vigentes': contratosVigentes,
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
