import 'package:flutter_test/flutter_test.dart';
import 'package:ms_inmuebles_app/core/utils/formatters.dart';
import 'package:ms_inmuebles_app/data/models/dashboard_kpi_model.dart';
import 'package:ms_inmuebles_app/data/models/contrato_model.dart';
import 'package:ms_inmuebles_app/data/models/inquilino_model.dart';
import 'package:ms_inmuebles_app/data/models/tenant_perfil_model.dart';
import 'package:ms_inmuebles_app/presentation/screens/setup/qr_scanner_screen.dart';

void main() {
  group('Pruebas de Formateadores', () {
    test('Formateo de moneda básico y nulo', () {
      expect(AppFormatters.currency(1500.5), equals('\$1,500.50'));
      expect(AppFormatters.currency(null), equals('\$0.00'));
    });

    test('Formateo de porcentajes', () {
      expect(AppFormatters.percentage(85.5), equals('85.5%'));
      expect(AppFormatters.percentage(null), equals('0%'));
    });

    test('Formateo inteligente de metraje (área m²)', () {
      expect(AppFormatters.area(1500000), equals('1.50 M m²'));
      expect(AppFormatters.area(2000000), equals('2 M m²'));
      expect(AppFormatters.area(150.5), equals('150.5 m²'));
      expect(AppFormatters.area(null), equals(''));
    });
  });

  group('Pruebas de Deserialización de Modelos JSON', () {
    test('DashboardKpiModel parsea exactamente la respuesta del backend', () {
      final jsonSample = {
        "inmuebles": {
          "total": 143
        },
        "jerarquia": {
          "princ_activas": 6,
          "princ_inactivas": 13,
          "sub_activas": 124,
          "sub_inactivas": 0
        },
        "tasa_ocupacion": 79.5,
        "ingresos_mensuales_proyectados": 24500.0,
        "distribucion_tipos_estado": [
          {"tipo": "Bodega", "estado": "rentado", "cantidad": "106"},
          {"tipo": "Bodega", "estado": "disponible", "cantidad": "6"},
          {"tipo": "Oficina", "estado": "rentado", "cantidad": "8"}
        ]
      };

      final model = DashboardKpiModel.fromJson(jsonSample);

      expect(model.inmuebles.total, equals(143));
      expect(model.jerarquia.princActivas, equals(6));
      expect(model.jerarquia.princInactivas, equals(13));
      expect(model.jerarquia.subActivas, equals(124));
      expect(model.jerarquia.subInactivas, equals(0));

      expect(model.distribucionTiposEstado.length, equals(5));
      expect(model.distribucionTiposEstado[0].tipo, equals('Edificio'));
      expect(model.distribucionTiposEstado[1].tipo, equals('Bodega'));
      expect(model.distribucionTiposEstado[1].ocupadas, equals(106));
    });

    test('ContratoModel calcula correctamente MRR mensual y normalización anual', () {
      final contratoMensual = ContratoModel.fromJson({
        "id": "10",
        "numero_contrato": "REF-2025-A",
        "fecha_inicio": "2025-01-01",
        "fecha_fin": "2026-01-01",
        "valor_pactado": "2500.00",
        "frecuencia_pago": "mensual",
        "estado": "vigente",
        "inquilino": "Juan Perez",
        "inmueble_nombre": "Bodega M2",
        "metraje": "350.50",
        "propietario": "Rosenheimer S.A."
      });

      final contratoAnual = ContratoModel.fromJson({
        "id": "11",
        "numero_contrato": "REF-2025-B",
        "fecha_inicio": "2025-01-01",
        "fecha_fin": "2026-01-01",
        "valor_pactado": "24000.00",
        "frecuencia_pago": "anual",
        "estado": "vigente",
        "inquilino": "Empresa Grande",
      });

      expect(contratoMensual.valorMensualizado, equals(2500.0));
      expect(contratoAnual.valorMensualizado, equals(2000.0));
      expect(contratoMensual.nombresInquilino, equals('Juan Perez'));
      expect(contratoMensual.inmuebleNombre, equals('Bodega M2'));
    });

    test('InquilinoModel calcula estado activo según contratos vigentes', () {
      final inquilinoActivo = InquilinoModel.fromJson({
        "id": 1,
        "identificacion": "1712345678",
        "nombres_razon_social": "Carlos Mendoza",
        "contratos_vigentes": 2
      });

      expect(inquilinoActivo.isActivo, isTrue);
    });

    test(r'QrCredentialsResult parsea correctamente la tarjeta QR con separador -$-', () {
      const qrRaw = r'https://api.metasociedad.com/wp-json/msinm/v1/ -$- VBamcjz4FfHBxxAFq2HqNYWBTu2piIoNBZDoHfXY -$- MS-001';
      final credentials = QrCredentialsResult.parse(qrRaw);

      expect(credentials, isNotNull);
      expect(credentials!.apiUrl, equals('https://api.metasociedad.com/wp-json/msinm/v1/'));
      expect(credentials.apiKey, equals('VBamcjz4FfHBxxAFq2HqNYWBTu2piIoNBZDoHfXY'));
      expect(credentials.tenantId, equals('MS-001'));
    });

    test('TenantPerfilModel parsea correctamente la respuesta de branding (/tenant/perfil)', () {
      final jsonSample = {
        "tenant_id": "ESLIVE_SA",
        "identificador": "Empresa Eslive Inmobiliaria",
        "app_banner": "https://conector-cliente.com/wp-content/uploads/2026/10/banner-hero.jpg"
      };

      final perfil = TenantPerfilModel.fromJson(jsonSample);

      expect(perfil.tenantId, equals('ESLIVE_SA'));
      expect(perfil.identificador, equals('Empresa Eslive Inmobiliaria'));
      expect(perfil.appBanner, equals('https://conector-cliente.com/wp-content/uploads/2026/10/banner-hero.jpg'));
    });

    test('InquilinoModel parsea logo corporativo del cliente', () {
      final jsonClient = {
        "id": "5",
        "tenant_id": "EMPRESA_SA",
        "identificacion": "0999999999",
        "nombres_razon_social": "Rosenheimer S.A.",
        "email": "contacto@rosenheimer.com",
        "telefono": "0987654321",
        "direccion": "Av. Principal 123",
        "logo": "https://tu-servidor.com/wp-content/uploads/2026/09/logo-rosenheimer.png",
        "contratos_vigentes": "2"
      };

      final inq = InquilinoModel.fromJson(jsonClient);

      expect(inq.id, equals(5));
      expect(inq.nombresRazonSocial, equals('Rosenheimer S.A.'));
      expect(inq.logo, equals('https://tu-servidor.com/wp-content/uploads/2026/09/logo-rosenheimer.png'));
      expect(inq.isActivo, isTrue);
    });

    test('DashboardKpiModel no tiene valores falsos hardcodeados por defecto', () {
      final emptyModel = DashboardKpiModel(
        inmuebles: InmueblesDesglose(),
        jerarquia: JerarquiaDesglose(),
        tasaOcupacion: 0.0,
        ingresosMensualesProyectados: 0.0,
        distribucionTiposEstado: [],
      );

      expect(emptyModel.displayRentaMensual, equals(0.0));
      expect(emptyModel.displayTasaOcupacion, equals(0.0));
      expect(emptyModel.displayAreaTotal, equals(0.0));
      expect(emptyModel.displayAreaOcupada, equals(0.0));
      expect(emptyModel.displayAreaVacante, equals(0.0));
      expect(emptyModel.displayRentaPromedioM2, equals(0.0));
      expect(emptyModel.displayRentaPotencial, equals(0.0));
      expect(emptyModel.displayTendenciaRentaMensual, isNull);
      expect(emptyModel.displayTendenciaRentaPromedio, isNull);
      expect(emptyModel.displayTendenciaRentaPotencial, isNull);
    });

    test('Cálculo de métricas de portafolio inmobiliario respeta fórmulas reales', () {
      const areaRentable = 10000.0;
      const areaRentada = 8000.0;
      const rentaMensual = 40000.0;

      // 1. Tasa Ocupación m² = (m² rentados / m² rentables) * 100
      const tasaOcupacion = (areaRentada / areaRentable) * 100;
      expect(tasaOcupacion, equals(80.0));

      // 2. Área Vacante = Área rentable - Área rentada
      const areaVacante = areaRentable - areaRentada;
      expect(areaVacante, equals(2000.0));

      // 3. Renta promedio por m² = Renta mensual / Área rentada
      const rentaPromedioM2 = rentaMensual / areaRentada;
      expect(rentaPromedioM2, equals(5.0));

      // 4. Renta potencial (100%) = Renta promedio por m² * Área total rentable
      const rentaPotencial = rentaPromedioM2 * areaRentable;
      expect(rentaPotencial, equals(50000.0));

      // 5. Upside = Renta potencial - Renta mensual
      const upside = rentaPotencial - rentaMensual;
      expect(upside, equals(10000.0));

      final model = DashboardKpiModel(
        inmuebles: InmueblesDesglose(),
        jerarquia: JerarquiaDesglose(),
        tasaOcupacion: tasaOcupacion,
        ingresosMensualesProyectados: rentaMensual,
        distribucionTiposEstado: [],
        areaTotalRentable: areaRentable,
        areaOcupada: areaRentada,
        areaVacante: areaVacante,
        rentaPromedioM2: rentaPromedioM2,
        rentaPotencialTotal: rentaPotencial,
      );

      expect(model.displayTasaOcupacion, equals(80.0));
      expect(model.displayAreaTotal, equals(10000.0));
      expect(model.displayAreaOcupada, equals(8000.0));
      expect(model.displayAreaVacante, equals(2000.0));
      expect(model.displayRentaPromedioM2, equals(5.0));
      expect(model.displayRentaPotencial, equals(50000.0));
    });

    test('DashboardKpiModel deserializa correctamente rentabilidad_ubicacion', () {
      final jsonSample = {
        "inmuebles": {"total": 117},
        "jerarquia": {"princ_activas": 2, "princ_inactivas": 0, "sub_activas": 115, "sub_inactivas": 0},
        "tasa_ocupacion": 100.0,
        "ingresos_mensuales_proyectados": 283000.0,
        "distribucion_tipos_estado": [],
        "rentabilidad_ubicacion": [
          {
            "ubicacion": "Parque Industrial Norte",
            "cantidad": "106",
            "promedio": "1113.20",
            "promedio_m2": "4.85"
          },
          {
            "ubicacion": "Av. República y Amazonas",
            "cantidad": "11",
            "promedio": "15000.00",
            "promedio_m2": "12.50"
          }
        ]
      };

      final model = DashboardKpiModel.fromJson(jsonSample);

      expect(model.rentabilidadUbicacion.length, equals(2));
      expect(model.rentabilidadUbicacion[0].ubicacion, equals('Parque Industrial Norte'));
      expect(model.rentabilidadUbicacion[0].cantidad, equals(106));
      expect(model.rentabilidadUbicacion[0].promedio, equals(1113.20));
      expect(model.rentabilidadUbicacion[0].promedioM2, equals(4.85));

      expect(model.rentabilidadUbicacion[1].ubicacion, equals('Av. República y Amazonas'));
      expect(model.rentabilidadUbicacion[1].cantidad, equals(11));
      expect(model.rentabilidadUbicacion[1].promedio, equals(15000.00));
      expect(model.rentabilidadUbicacion[1].promedioM2, equals(12.50));
    });
  });
}
