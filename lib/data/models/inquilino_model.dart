/// Modelo para Inquilinos / Directorio de Clientes (/inquilinos).
class InquilinoModel {
  final int id;
  final String? tenantId;
  final String identificacion;
  final String nombresRazonSocial; // Nombre Referencial / Comercial
  final String? razonSocial; // Razón Social Legal (Opcional)
  final String? email; // Correo de Contacto
  final String? emailRecordatorios; // Correo para Recordatorios (Vencimiento de contratos y cobros SMTP)
  final String? telefono;
  final String? direccion;
  final String? logo;
  final int contratosVigentes;

  InquilinoModel({
    required this.id,
    this.tenantId,
    required this.identificacion,
    required this.nombresRazonSocial,
    this.razonSocial,
    this.email,
    this.emailRecordatorios,
    this.telefono,
    this.direccion,
    this.logo,
    this.contratosVigentes = 0,
  });

  bool get isActivo => contratosVigentes > 0;

  factory InquilinoModel.fromJson(Map<String, dynamic> json) {
    final rawEmail = json['email']?.toString();
    final rawEmailRec = json['email_recordatorios']?.toString();
    final rawTel = json['telefono']?.toString();
    final rawDir = json['direccion']?.toString();
    final rawLogo = json['logo']?.toString() ?? json['logo_url']?.toString();
    final rawRS = json['razon_social']?.toString();

    // Nombre referencial: preferimos nombres_razon_social o nombre_referencial o nombre
    final String nombreRef = json['nombres_razon_social']?.toString() ??
        json['nombre_referencial']?.toString() ??
        json['nombre']?.toString() ??
        (rawRS != null && rawRS.trim().isNotEmpty ? rawRS.trim() : 'Inquilino');

    return InquilinoModel(
      id: _toInt(json['id']),
      tenantId: json['tenant_id']?.toString(),
      identificacion: json['identificacion']?.toString() ?? json['cedula']?.toString() ?? json['ruc']?.toString() ?? '',
      nombresRazonSocial: nombreRef.trim(),
      razonSocial: (rawRS != null && rawRS.trim().isNotEmpty) ? rawRS.trim() : null,
      email: (rawEmail != null && rawEmail.trim().isNotEmpty) ? rawEmail.trim() : null,
      emailRecordatorios: (rawEmailRec != null && rawEmailRec.trim().isNotEmpty) ? rawEmailRec.trim() : null,
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
      if (razonSocial != null) 'razon_social': razonSocial,
      if (tenantId != null) 'tenant_id': tenantId,
      if (email != null) 'email': email,
      if (emailRecordatorios != null) 'email_recordatorios': emailRecordatorios,
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
