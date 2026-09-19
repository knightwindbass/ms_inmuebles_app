/// Modelo para la personalización y marca blanca del Tenant (/tenant/perfil).
class TenantPerfilModel {
  final String? tenantId;
  final String? identificador;
  final String? appBanner;
  final String? logo;
  final String? slogan;

  const TenantPerfilModel({
    this.tenantId,
    this.identificador,
    this.appBanner,
    this.logo,
    this.slogan,
  });

  factory TenantPerfilModel.fromJson(Map<String, dynamic> json) {
    // Si viene anidado en 'data' o 'result'
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['result'] is Map<String, dynamic>)
            ? json['result'] as Map<String, dynamic>
            : json;

    final rawBanner = data['app_banner'] ?? data['banner_url'] ?? data['banner'] ?? data['hero_banner'];
    final rawLogo = data['logo'] ?? data['logo_url'] ?? data['app_logo'];
    final rawIdentificador = data['identificador'] ?? data['nombre'] ?? data['nombres_razon_social'] ?? data['razon_social'];
    final rawSlogan = data['slogan'] ?? data['eslogan'] ?? data['subtitulo'];

    return TenantPerfilModel(
      tenantId: data['tenant_id']?.toString(),
      identificador: rawIdentificador != null && rawIdentificador.toString().trim().isNotEmpty
          ? rawIdentificador.toString().trim()
          : null,
      appBanner: rawBanner != null && rawBanner.toString().trim().isNotEmpty
          ? rawBanner.toString().trim()
          : null,
      logo: rawLogo != null && rawLogo.toString().trim().isNotEmpty
          ? rawLogo.toString().trim()
          : null,
      slogan: rawSlogan != null && rawSlogan.toString().trim().isNotEmpty
          ? rawSlogan.toString().trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tenantId != null) 'tenant_id': tenantId,
      if (identificador != null) 'identificador': identificador,
      if (appBanner != null) 'app_banner': appBanner,
      if (logo != null) 'logo': logo,
      if (slogan != null) 'slogan': slogan,
    };
  }

  TenantPerfilModel copyWith({
    String? tenantId,
    String? identificador,
    String? appBanner,
    String? logo,
    String? slogan,
  }) {
    return TenantPerfilModel(
      tenantId: tenantId ?? this.tenantId,
      identificador: identificador ?? this.identificador,
      appBanner: appBanner ?? this.appBanner,
      logo: logo ?? this.logo,
      slogan: slogan ?? this.slogan,
    );
  }
}
