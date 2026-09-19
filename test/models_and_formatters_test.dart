import 'package:flutter_test/flutter_test.dart';
import 'package:ms_inmuebles_app/core/utils/formatters.dart';
import 'package:ms_inmuebles_app/data/models/dashboard_kpi_model.dart';
import 'package:ms_inmuebles_app/data/models/contrato_model.dart';
import 'package:ms_inmuebles_app/data/models/inquilino_model.dart';
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
  });
}
