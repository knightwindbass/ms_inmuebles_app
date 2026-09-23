import 'package:flutter_test/flutter_test.dart';
import 'package:ms_inmuebles_app/core/theme/app_theme.dart';
import 'package:ms_inmuebles_app/core/utils/formatters.dart';
import 'package:ms_inmuebles_app/data/models/dashboard_kpi_model.dart';
import 'package:ms_inmuebles_app/data/models/contrato_model.dart';
import 'package:ms_inmuebles_app/data/models/inquilino_model.dart';
import 'package:ms_inmuebles_app/data/models/tenant_perfil_model.dart';
import 'package:ms_inmuebles_app/data/models/inmueble_model.dart';
import 'package:ms_inmuebles_app/data/repositories/inmuebles_repository.dart';
import 'package:ms_inmuebles_app/logic/inmuebles_provider.dart';
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

    test('ContratoModel agrupa correctamente contratos por ID consolidando montos y múltiples inmuebles', () {
      final rawList = [
        ContratoModel.fromJson({
          "id": "15",
          "numero_contrato": "CTR-BODEGAS-01",
          "fecha_inicio": "2025-01-01",
          "fecha_fin": "2026-01-01",
          "valor_pactado": "500.00",
          "frecuencia_pago": "mensual",
          "estado": "vigente",
          "inquilino": "Logística Global S.A.",
          "inmueble_nombre": "Bodega 101",
          "metraje": "200.00",
          "propietario": "Rosenheimer S.A."
        }),
        ContratoModel.fromJson({
          "id": "15",
          "numero_contrato": "CTR-BODEGAS-01",
          "fecha_inicio": "2025-01-01",
          "fecha_fin": "2026-01-01",
          "valor_pactado": "700.00",
          "frecuencia_pago": "mensual",
          "estado": "vigente",
          "inquilino": "Logística Global S.A.",
          "inmueble_nombre": "Bodega 102",
          "metraje": "300.00",
          "propietario": "Rosenheimer S.A."
        }),
        ContratoModel.fromJson({
          "id": "16",
          "numero_contrato": "CTR-LOCAL-02",
          "fecha_inicio": "2025-02-01",
          "fecha_fin": "2026-02-01",
          "valor_pactado": "400.00",
          "frecuencia_pago": "mensual",
          "estado": "vigente",
          "inquilino": "Cafetería Express",
          "inmueble_nombre": "Local Comercial 1",
          "metraje": "45.00"
        }),
      ];

      final grouped = ContratoModel.groupContratos(rawList);

      // Debe haber exactamente 2 contratos únicos (ID 15 y ID 16)
      expect(grouped.length, equals(2));

      // Contrato ID 15 consolidado
      final c15 = grouped.firstWhere((c) => c.id == 15);
      expect(c15.numeroContrato, equals('CTR-BODEGAS-01'));
      expect(c15.nombresInquilino, equals('Logística Global S.A.'));
      // Monto acumulado de las 2 bodegas: 500 + 700 = 1200
      expect(c15.valorPactado, equals(1200.0));
      // Metraje acumulado: 200 + 300 = 500
      expect(c15.totalMetraje, equals(500.0));
      // Inmuebles asociados
      expect(c15.tieneMultiplesInmuebles, isTrue);
      expect(c15.cantidadInmuebles, equals(2));
      expect(c15.inmueblesAsociados[0].nombre, equals('Bodega 101'));
      expect(c15.inmueblesAsociados[0].valor, equals(500.0));
      expect(c15.inmueblesAsociados[1].nombre, equals('Bodega 102'));
      expect(c15.inmueblesAsociados[1].valor, equals(700.0));
      expect(c15.resumenInmuebles, contains('Bodega 101'));
      expect(c15.resumenInmuebles, contains('Bodega 102'));

      // Contrato ID 16 individual
      final c16 = grouped.firstWhere((c) => c.id == 16);
      expect(c16.valorPactado, equals(400.0));
      expect(c16.cantidadInmuebles, equals(1));
      expect(c16.tieneMultiplesInmuebles, isFalse);

      // Verificación de conteo de contratos vigentes
      final vigentes = grouped.where((c) => c.isVigente).length;
      expect(vigentes, equals(2)); // 2 contratos vigentes reales, no 3 filas
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
            "promedio_m2": "12.50",
            "total": "165000.00"
          }
        ]
      };

      final model = DashboardKpiModel.fromJson(jsonSample);

      expect(model.rentabilidadUbicacion.length, equals(2));
      expect(model.rentabilidadUbicacion[0].ubicacion, equals('Parque Industrial Norte'));
      expect(model.rentabilidadUbicacion[0].cantidad, equals(106));
      expect(model.rentabilidadUbicacion[0].promedio, equals(1113.20));
      expect(model.rentabilidadUbicacion[0].total, closeTo(117999.20, 0.01));
      expect(model.rentabilidadUbicacion[0].promedioM2, equals(4.85));

      expect(model.rentabilidadUbicacion[1].ubicacion, equals('Av. República y Amazonas'));
      expect(model.rentabilidadUbicacion[1].cantidad, equals(11));
      expect(model.rentabilidadUbicacion[1].promedio, equals(15000.00));
      expect(model.rentabilidadUbicacion[1].total, equals(165000.00));
      expect(model.rentabilidadUbicacion[1].promedioM2, equals(12.50));
    });

    test('ContratoModel mergeWith preserva el canon exacto sin triplicarlo al consultar detalle o unir filas', () {
      final itemPrincipal = ContratoModel(
        id: 1789754440,
        numeroContrato: 'C-1789754440',
        fechaInicio: '2025-01-01',
        fechaFin: '2026-01-01',
        valorPactado: 25122.10,
        nombresInquilino: 'DinatekPower S.A.',
        inmueblesAsociados: [
          ContratoInmuebleInfo(
            nombre: 'Multiparque – Taller / Oficina Dinatek',
            valor: 25122.10,
            metraje: 5024.52,
          ),
        ],
      );

      final filaSecundaria = ContratoModel(
        id: 1789754440,
        numeroContrato: 'C-1789754440',
        fechaInicio: '2025-01-01',
        fechaFin: '2026-01-01',
        valorPactado: 25122.10, // En JOIN de BD se repite el canon del contrato
        nombresInquilino: 'DinatekPower S.A.',
        inmueblesAsociados: [
          ContratoInmuebleInfo(
            nombre: 'Multiparque – Bodega 01',
            valor: 0.0,
            metraje: 0.0,
          ),
        ],
      );

      // Primer merge: agrupa las dos propiedades
      final consolidado = itemPrincipal.mergeWith(filaSecundaria);
      expect(consolidado.inmueblesAsociados.length, equals(2));
      // El canon NO debe ser 50,244.20, debe mantenerse en 25,122.10
      expect(consolidado.valorPactado, equals(25122.10));

      // Segundo merge simulado (ej. getDetalle remoto)
      final conDetalleRemoto = consolidado.mergeWith(itemPrincipal);
      expect(conDetalleRemoto.inmueblesAsociados.length, equals(2));
      // El canon NO debe triplicarse a 75,366.30
      expect(conDetalleRemoto.valorPactado, equals(25122.10));
    });

    test('InmueblesProvider calcula correctamente métricas de auditoría en portafolio y filtros', () async {
      final fakeData = [
        // Complejo matriz (id 1)
        InmuebleModel(
          id: 1,
          nombre: 'Multiparque Matriz',
          tipo: 'Edificio',
          estado: 'rentado',
          metraje: 15000.0,
          valorRentaBase: 75000.0,
        ),
        // Sub-unidad 1 (rentada)
        InmuebleModel(
          id: 2,
          propiedadPadreId: 1,
          nombre: 'Bodega 1',
          tipo: 'Bodega',
          estado: 'rentado',
          metraje: 5000.0,
          valorRentaBase: 25000.0,
        ),
        // Sub-unidad 2 (disponible)
        InmuebleModel(
          id: 3,
          propiedadPadreId: 1,
          nombre: 'Bodega 2',
          tipo: 'Bodega',
          estado: 'disponible',
          metraje: 10000.0,
          valorRentaBase: 50000.0,
        ),
      ];

      final repo = _FakeInmueblesRepository(fakeData);
      final provider = InmueblesProvider(repo);
      await provider.fetchInmuebles();

      // En modo sin filtros, totalAreaAudit y totalRentaRentados excluyen matrices para evitar duplicar
      expect(provider.topLevelInmuebles.length, equals(1));
      expect(provider.totalRentados, equals(1)); // Solo Bodega 1 leasable
      expect(provider.totalDisponibles, equals(1)); // Bodega 2 leasable
      expect(provider.totalAreaAudit, equals(15000.0)); // 5000 + 10000 (excluye id 1 que es padre)
      expect(provider.totalAreaFilasBrutas, equals(30000.0)); // 15000 + 5000 + 10000
      expect(provider.totalRentaRentados, equals(25000.0)); // Solo unidades leasables (no duplica matriz de 75000)
      expect(provider.totalRentaFilasBrutas, equals(100000.0)); // Bruto en filas: 75000 + 25000
      expect(provider.totalRentaBasePortafolio, equals(75000.0)); // 25000 + 50000
    });

    test('ContratoModel agrupa múltiples bodegas con el mismo canon sin ignorarlas y reconoce estado activo/vigente', () {
      final item1 = ContratoModel(
        id: 99,
        numeroContrato: 'CTR-SAME-PRICE',
        fechaInicio: '2025-01-01',
        fechaFin: '2026-01-01',
        valorPactado: 500.0,
        estado: 'activo',
        nombresInquilino: 'Comercial ABC',
        inmueblesAsociados: [
          ContratoInmuebleInfo(inmuebleId: 101, nombre: 'Bodega Norte 1', valor: 500.0, metraje: 100.0),
        ],
      );

      final item2 = ContratoModel(
        id: 99,
        numeroContrato: 'CTR-SAME-PRICE',
        fechaInicio: '2025-01-01',
        fechaFin: '2026-01-01',
        valorPactado: 500.0, // Mismo valor que item1
        estado: 'vigente',
        nombresInquilino: 'Comercial ABC',
        inmueblesAsociados: [
          ContratoInmuebleInfo(inmuebleId: 102, nombre: 'Bodega Norte 2', valor: 500.0, metraje: 100.0),
        ],
      );

      final consolidado = item1.mergeWith(item2);
      expect(consolidado.isVigente, isTrue);
      expect(consolidado.cantidadInmuebles, equals(2));
      // Debe sumar 500 + 500 = 1000
      expect(consolidado.valorPactado, equals(1000.0));
      expect(consolidado.totalMetraje, equals(200.0));
    });

    test('ContratoModel parsea inquilino_id y permite consolidar contratos por inquilino', () {
      final jsonContrato1 = {
        'id': '101',
        'numero_contrato': 'CTR-INQ-1',
        'inquilino_id': '45',
        'inquilino': 'Distribuidora Global S.A.',
        'identificacion': '0999999999001',
        'inmueble_nombre': 'Bodega Central',
        'valor_pactado': '3200.00',
        'frecuencia_pago': 'mensual',
        'estado': 'vigente',
        'metraje': '500.0',
        'fecha_inicio': '2025-01-01',
        'fecha_fin': '2026-01-01',
      };

      final jsonContrato2 = {
        'id': '102',
        'numero_contrato': 'CTR-INQ-2',
        'inquilino_id': '45',
        'inquilino': 'Distribuidora Global S.A.',
        'identificacion': '0999999999001',
        'inmueble_nombre': 'Oficina 301',
        'valor_pactado': '800.00',
        'frecuencia_pago': 'mensual',
        'estado': 'vigente',
        'metraje': '80.0',
        'fecha_inicio': '2025-01-01',
        'fecha_fin': '2026-01-01',
      };

      final c1 = ContratoModel.fromJson(jsonContrato1);
      final c2 = ContratoModel.fromJson(jsonContrato2);

      expect(c1.inquilinoId, equals(45));
      expect(c2.inquilinoId, equals(45));

      final inquilino = InquilinoModel(
        id: 45,
        identificacion: '0999999999001',
        nombresRazonSocial: 'Distribuidora Global S.A.',
        contratosVigentes: 2,
      );

      final listaContratos = [c1, c2];
      final matched = listaContratos.where((c) =>
          c.inquilinoId == inquilino.id ||
          c.identificacionInquilino == inquilino.identificacion ||
          c.nombresInquilino.toLowerCase() == inquilino.nombresRazonSocial.toLowerCase()
      ).toList();

      expect(matched.length, equals(2));
      final totalMRR = matched.fold(0.0, (acc, c) => acc + c.valorMensualizado);
      final totalArea = matched.fold(0.0, (acc, c) => acc + c.totalMetraje);

      expect(totalMRR, equals(4000.0));
      expect(totalArea, equals(580.0));
    });

    test('DashboardKpiModel y InmueblesDesglose procesan métricas exclusivas de Land Banking', () {
      final jsonLandBanking = {
        "inmuebles": {
          "total": 12,
          "area_total": 450000.50,
          "disponible": 4,
          "aportado": 3,
          "disponible_sin_rellenar": 2,
          "en_desarrollo": 3
        }
      };

      final model = DashboardKpiModel.fromJson(jsonLandBanking);

      expect(model.inmuebles.total, equals(12));
      expect(model.inmuebles.areaTotal, equals(450000.50));
      expect(model.inmuebles.disponibles, equals(4));
      expect(model.inmuebles.aportados, equals(3));
      expect(model.inmuebles.disponibleSinRellenar, equals(2));
      expect(model.inmuebles.enDesarrollo, equals(3));
    });

    test('AppTheme asigna colores semánticos correctos a los 4 estados de Land Banking', () {
      expect(
        AppTheme.getColorForEstado('Disponible (Listo para desarrollo)'),
        equals(AppTheme.statusDisponible),
      );
      expect(
        AppTheme.getColorForEstado('Aportado (Fideicomiso)'),
        equals(AppTheme.statusAportado),
      );
      expect(
        AppTheme.getColorForEstado('Disponible / Sin Rellenar'),
        equals(AppTheme.statusSinRellenar),
      );
      expect(
        AppTheme.getColorForEstado('En Desarrollo / Rellenado'),
        equals(AppTheme.statusEnDesarrollo),
      );
    });

    test('InmuebleModel normaliza tipología Terreno (Land Banking)', () {
      expect(InmuebleModel.normalizeTipo('Terreno (Land Banking)'), equals('Terreno'));
      expect(InmuebleModel.normalizeTipo('terreno'), equals('Terreno'));
      expect(InmuebleModel.normalizeTipo('TERRENO'), equals('Terreno'));
    });

    test('DashboardKpiModel calcula exactamente la Renta Anual Proyectada (displayRentaAnual)', () {
      final model = DashboardKpiModel(
        inmuebles: InmueblesDesglose(total: 10),
        jerarquia: JerarquiaDesglose(),
        tasaOcupacion: 95.0,
        ingresosMensualesProyectados: 25000.0,
        distribucionTiposEstado: [],
      );

      expect(model.displayRentaMensual, equals(25000.0));
      expect(model.displayRentaAnual, equals(300000.0)); // 25,000 * 12
    });

    test('InmuebleModel calcula y expone valorM2 correctamente', () {
      // Caso 1: Calculado a partir de valorRentaBase y metraje (ej. Lote 1 de la API)
      final lote1 = InmuebleModel.fromJson({
        'id': 112,
        'nombre': 'Lote 1',
        'tipo': 'Terreno',
        'metraje': '878818.00',
        'valor_renta_base': '2416749.50',
      });
      expect(lote1.valorM2, closeTo(2.75, 0.01));

      // Caso 2: Proporcionado explícitamente en el JSON (valor_m2)
      final loteExplicit = InmuebleModel.fromJson({
        'id': 113,
        'nombre': 'Lote 2',
        'tipo': 'Terreno',
        'metraje': '1000.00',
        'valor_renta_base': '50000.00',
        'valor_m2': '60.00',
      });
      expect(loteExplicit.valorM2, equals(60.0));

      // Caso 3: Sin metraje o metraje 0
      final loteCero = InmuebleModel.fromJson({
        'id': 114,
        'nombre': 'Lote 3',
        'tipo': 'Terreno',
        'metraje': '0',
        'valor_renta_base': '50000.00',
      });
      expect(loteCero.valorM2, equals(0.0));
    });

    test('InmueblesDesglose deserializa valorM2Promedio correctamente', () {
      final desglose1 = InmueblesDesglose.fromMap({
        'total': 5,
        'valor_m2_promedio': '2.75',
      });
      expect(desglose1.valorM2Promedio, equals(2.75));

      final desglose2 = InmueblesDesglose.fromMap({
        'total': 5,
        'precio_m2_promedio': 3.50,
      });
      expect(desglose2.valorM2Promedio, equals(3.50));
    });

    test('InmueblesDesglose deserializa valorTotal correctamente', () {
      final desglose = InmueblesDesglose.fromMap({
        'total': 2,
        'valor_referencial_total': '4500000.00',
      });
      expect(desglose.valorTotal, equals(4500000.0));
    });
  });
}

class _FakeInmueblesRepository implements InmueblesRepository {
  final List<InmuebleModel> mockList;
  _FakeInmueblesRepository(this.mockList);

  @override
  Future<List<InmuebleModel>> getInmuebles({
    String? estado,
    String? tipo,
    String? buscar,
    String? propietario,
    int? padreId,
    String? orden,
  }) async {
    return mockList;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
