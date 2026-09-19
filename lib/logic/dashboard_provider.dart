import 'package:flutter/material.dart';
import '../data/models/dashboard_kpi_model.dart';
import '../data/models/inmueble_model.dart';
import '../data/models/tenant_perfil_model.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/inmuebles_repository.dart';

/// Proveedor de estado para el Dashboard de Inteligencia de Negocios y Reportes.
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;
  final InmueblesRepository? _inmueblesRepository;

  DashboardKpiModel? _kpis;
  TenantPerfilModel? _tenantPerfil;
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedPadreId;

  DashboardProvider(this._repository, [this._inmueblesRepository]);

  DashboardKpiModel? get kpis => _kpis;
  TenantPerfilModel? get tenantPerfil => _tenantPerfil;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedPadreId => _selectedPadreId;

  String? get bannerUrl => _tenantPerfil?.appBanner ?? _kpis?.bannerUrl;
  String? get logoUrl => _tenantPerfil?.logo ?? _kpis?.logoUrl;
  String? get slogan => _tenantPerfil?.slogan ?? _kpis?.slogan;

  Future<void> fetchDashboard({int? padreId}) async {
    _selectedPadreId = padreId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Obtener la respuesta directa del endpoint del Dashboard (/dashboard/resumen)
      final kpisResult = await _repository.getResumen(padreId: _selectedPadreId);

      // 2. Obtener opcionalmente personalización de branding del Tenant (/tenant/perfil)
      try {
        final perfilResult = await _repository.getTenantPerfil();
        if (perfilResult != null) {
          _tenantPerfil = perfilResult;
        }
      } catch (_) {}

      // Si tenemos branding de tenant, enriquecer los KPIs con banner/logo/slogan
      if (_tenantPerfil != null) {
        _kpis = kpisResult.copyWith(
          bannerUrl: _tenantPerfil!.appBanner ?? kpisResult.bannerUrl,
          logoUrl: _tenantPerfil!.logo ?? kpisResult.logoUrl,
          slogan: _tenantPerfil!.slogan ?? kpisResult.slogan,
        );
      } else {
        _kpis = kpisResult;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 3. Fallback de contingencia si el endpoint falla: calcular desde /inmuebles
      if (_inmueblesRepository != null) {
        try {
          final inmueblesList = await _inmueblesRepository!.getInmuebles(padreId: _selectedPadreId);
          _kpis = _calculateFromInmuebles(inmueblesList);
          _isLoading = false;
          notifyListeners();
          return;
        } catch (_) {}
      }

      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  DashboardKpiModel _calculateFromInmuebles(List<InmuebleModel> list) {
    int disp = 0;
    int rent = 0;
    int mant = 0;
    int inac = 0;

    int pAct = 0;
    int pInac = 0;
    int sAct = 0;
    int sInac = 0;

    final Map<String, List<int>> mapTipos = {};
    for (final tipo in DashboardKpiModel.labelsTipos) {
      mapTipos[tipo] = [0, 0];
    }

    double mrr = 0.0;

    for (final item in list) {
      final isDispon = item.isDisponible;
      final isRent = item.isRentado;
      final isMant = item.isMantenimiento;
      final isInac = item.isInactivo;

      if (isDispon) {
        disp++;
      } else if (isRent) {
        rent++;
        mrr += item.valorRentaBase;
      } else if (isMant) {
        mant++;
      } else if (isInac) {
        inac++;
      }

      // Jerarquía
      if (item.isSubunidad) {
        if (isInac) {
          sInac++;
        } else {
          sAct++;
        }
      } else {
        if (isInac) {
          pInac++;
        } else {
          pAct++;
        }
      }

      // Distribución
      final tipoNorm = InmuebleModel.normalizeTipo(item.tipo);
      mapTipos.putIfAbsent(tipoNorm, () => [0, 0]);

      if (isRent) {
        mapTipos[tipoNorm]![1] += 1;
      } else if (isDispon) {
        mapTipos[tipoNorm]![0] += 1;
      }
    }

    final total = list.length;
    final tasa = total > 0 ? (rent / total) * 100 : 0.0;

    final distList = DashboardKpiModel.labelsTipos.map((tipo) {
      final counts = mapTipos[tipo] ?? [0, 0];
      return DistribucionTipoEstado(
        tipo: tipo,
        libres: counts[0],
        ocupadas: counts[1],
      );
    }).toList();

    return DashboardKpiModel(
      inmuebles: InmueblesDesglose(
        total: total,
        disponibles: disp,
        rentados: rent,
        mantenimiento: mant,
        inactivo: inac,
      ),
      jerarquia: JerarquiaDesglose(
        princActivas: pAct,
        princInactivas: pInac,
        subActivas: sAct,
        subInactivas: sInac,
      ),
      tasaOcupacion: tasa,
      ingresosMensualesProyectados: mrr,
      distribucionTiposEstado: distList,
    );
  }

  void filterByMatriz(int? padreId) {
    if (_selectedPadreId == padreId) return;
    fetchDashboard(padreId: padreId);
  }

  Future<void> refresh() async {
    await fetchDashboard(padreId: _selectedPadreId);
  }
}
