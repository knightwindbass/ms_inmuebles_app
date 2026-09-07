/// Constantes globales de configuración de red y catálogos para MS Inmuebles SaaS.
class ApiConstants {
  static const String defaultBaseUrl = 'https://tu-servidor.com/wp-json/msinm/v1';

  // Endpoints
  static const String dashboardResumen = '/dashboard/resumen';
  static const String inmuebles = '/inmuebles';
  static const String inquilinos = '/inquilinos';
  static const String contratos = '/contratos';

  // Headers Multi-Tenant
  static const String headerApiKey = 'x-api-key';
  static const String headerTenantId = 'x-tenant-id';
  static const String headerContentType = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Catálogos - Estados de Inmuebles
  static const String estadoDisponible = 'disponible';
  static const String estadoRentado = 'rentado';
  static const String estadoMantenimiento = 'mantenimiento';
  static const String estadoInactivo = 'inactivo';

  static const List<String> estadosInmueble = [
    estadoDisponible,
    estadoRentado,
    estadoMantenimiento,
    estadoInactivo,
  ];

  // Catálogos - Tipologías de Inmuebles
  static const String tipoEdificio = 'Edificio';
  static const String tipoBodega = 'Bodega';
  static const String tipoLocal = 'Local';
  static const String tipoOficina = 'Oficina';
  static const String tipoTerreno = 'Terreno';

  static const List<String> tiposInmueble = [
    tipoEdificio,
    tipoBodega,
    tipoLocal,
    tipoOficina,
    tipoTerreno,
  ];

  // Opciones de Ordenación
  static const String ordenRentaAsc = 'renta_asc';
  static const String ordenRentaDesc = 'renta_desc';
  
  static const String ordenVencimientoAsc = 'vencimiento_asc';
  static const String ordenVencimientoDesc = 'vencimiento_desc';
  static const String ordenMontoDesc = 'monto_desc';
  static const String ordenMontoAsc = 'monto_asc';
  static const String ordenInquilinoAsc = 'inquilino_asc';
}
