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
      DashboardKpiModel kpisResult = await _repository.getResumen(padreId: _selectedPadreId);

      // 2. Obtener opcionalmente personalización de branding del Tenant (/tenant/perfil)
      try {
        final perfilResult = await _repository.getTenantPerfil();
        if (perfilResult != null) {
          _tenantPerfil = perfilResult;
        }
      } catch (_) {}

      // 3. Enriquecer con métricas de metraje real desde /inmuebles
      if (_inmueblesRepository != null) {
        try {
          final inmueblesList = await _inmueblesRepository!.getInmuebles(padreId: _selectedPadreId);
          kpisResult = _enrichKpisWithInmuebles(kpisResult, inmueblesList);
        } catch (_) {}
      }

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
      // 4. Fallback de contingencia si el endpoint falla: calcular desde /inmuebles
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

  /// Enriquece las métricas calculando ocupación m², renta promedio y potencial
  /// basados en las unidades arrendables reales (evitando duplicar matrices y subunidades).
  DashboardKpiModel _enrichKpisWithInmuebles(DashboardKpiModel baseKpis, List<InmuebleModel> list) {
    if (list.isEmpty) return baseKpis;

    // Detectar matrices para no duplicar metrajes de edificios y sus subunidades
    final parentIds = list
        .map((e) => e.propiedadPadreId)
        .where((id) => id != null && id > 0)
        .toSet();

    // Unidades arrendables: hijas o propiedades independientes sin subunidades
    final leasableUnits = list.where((e) => !parentIds.contains(e.id)).toList();

    // 1. Área total rentable (m²): suma de metrajes de unidades arrendables
    final double computedAreaTotal = leasableUnits.fold(0.0, (sum, u) => sum + (u.metraje ?? 0.0));

    // 2. Área ocupada / rentada (m²): suma de metrajes de unidades arrendables en estado 'rentado'
    final double computedAreaOcupada = leasableUnits
        .where((u) => u.isRentado)
        .fold(0.0, (sum, u) => sum + (u.metraje ?? 0.0));

    // 3. Área vacante (m²): total área rentable - área rentada
    final double computedAreaVacante = (computedAreaTotal >= computedAreaOcupada)
        ? (computedAreaTotal - computedAreaOcupada)
        : 0.0;

    // 4. Renta mensual base
    final double computedRentaInmuebles = leasableUnits
        .where((u) => u.isRentado)
        .fold(0.0, (sum, u) => sum + u.valorRentaBase);

    final double effectiveRentaMensual = (baseKpis.ingresosMensualesProyectados > 0)
        ? baseKpis.ingresosMensualesProyectados
        : computedRentaInmuebles;

    // 5. Tasa de ocupación en m²: (m² rentados / m² rentables) * 100
    final double computedTasaOcupacionM2 = (computedAreaTotal > 0)
        ? ((computedAreaOcupada / computedAreaTotal) * 100)
        : baseKpis.tasaOcupacion;

    // 6. Renta Promedio Portafolio: Renta mensual base / Total m² rentados
    final double computedRentaPromedioM2 = (computedAreaOcupada > 0)
        ? (effectiveRentaMensual / computedAreaOcupada)
        : 0.0;

    // 7. Renta Potencial (100%): Renta Promedio ($/m²) * Total Área Rentable
    final double computedRentaPotencial = (computedRentaPromedioM2 * computedAreaTotal);

    // 8. Rentabilidad por Ubicación (Complejos Rentados)
    List<RentabilidadUbicacion> effectiveRentabilidad = baseKpis.rentabilidadUbicacion;
    if (effectiveRentabilidad.isEmpty) {
      final rentedUnits = leasableUnits.where((u) => u.isRentado).toList();
      final Map<String, List<InmuebleModel>> groupedByLocation = {};
      for (final u in rentedUnits) {
        final loc = (u.direccion != null && u.direccion!.trim().isNotEmpty)
            ? u.direccion!.trim()
            : ((u.ciudad != null && u.ciudad!.trim().isNotEmpty)
                ? u.ciudad!.trim()
                : u.nombre.trim());
        groupedByLocation.putIfAbsent(loc, () => []).add(u);
      }
      effectiveRentabilidad = groupedByLocation.entries.map((entry) {
        final count = entry.value.length;
        final total = entry.value.fold(0.0, (sum, item) => sum + item.valorRentaBase);
        final totalM2 = entry.value.fold(0.0, (sum, item) => sum + (item.metraje ?? 0.0));
        return RentabilidadUbicacion(
          ubicacion: entry.key,
          cantidad: count,
          promedio: count > 0 ? (total / count) : 0.0,
          promedioM2: totalM2 > 0 ? (total / totalM2) : 0.0,
        );
      }).toList();
    }

    return baseKpis.copyWith(
      rentaMensualBase: baseKpis.rentaMensualBase ?? effectiveRentaMensual,
      areaTotalRentable: baseKpis.areaTotalRentable ?? computedAreaTotal,
      areaOcupada: baseKpis.areaOcupada ?? computedAreaOcupada,
      areaVacante: baseKpis.areaVacante ?? computedAreaVacante,
      tasaOcupacion: computedAreaTotal > 0 ? computedTasaOcupacionM2 : baseKpis.tasaOcupacion,
      rentaPromedioM2: baseKpis.rentaPromedioM2 ?? computedRentaPromedioM2,
      rentaPotencialTotal: baseKpis.rentaPotencialTotal ?? computedRentaPotencial,
      rentabilidadUbicacion: effectiveRentabilidad,
    );
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

    final parentIds = list
        .map((e) => e.propiedadPadreId)
        .where((id) => id != null && id > 0)
        .toSet();
    final leasableUnits = list.where((e) => !parentIds.contains(e.id)).toList();

    double totalArea = 0.0;
    double areaRentada = 0.0;

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

    for (final u in leasableUnits) {
      final m = u.metraje ?? 0.0;
      totalArea += m;
      if (u.isRentado) {
        areaRentada += m;
      }
    }

    final double areaVacante = (totalArea >= areaRentada) ? (totalArea - areaRentada) : 0.0;
    final double tasaM2 = totalArea > 0
        ? (areaRentada / totalArea) * 100
        : (list.isNotEmpty ? (rent / list.length) * 100 : 0.0);
    final double rentaPromM2 = areaRentada > 0 ? (mrr / areaRentada) : 0.0;
    final double rentaPotencial = rentaPromM2 * totalArea;

    // Rentabilidad por Ubicación
    final rentedUnits = leasableUnits.where((u) => u.isRentado).toList();
    final Map<String, List<InmuebleModel>> groupedByLocation = {};
    for (final u in rentedUnits) {
      final loc = (u.direccion != null && u.direccion!.trim().isNotEmpty)
          ? u.direccion!.trim()
          : ((u.ciudad != null && u.ciudad!.trim().isNotEmpty)
              ? u.ciudad!.trim()
              : u.nombre.trim());
      groupedByLocation.putIfAbsent(loc, () => []).add(u);
    }
    final computedRentabilidad = groupedByLocation.entries.map((entry) {
      final count = entry.value.length;
      final total = entry.value.fold(0.0, (sum, item) => sum + item.valorRentaBase);
      final totalM2 = entry.value.fold(0.0, (sum, item) => sum + (item.metraje ?? 0.0));
      return RentabilidadUbicacion(
        ubicacion: entry.key,
        cantidad: count,
        promedio: count > 0 ? (total / count) : 0.0,
        promedioM2: totalM2 > 0 ? (total / totalM2) : 0.0,
      );
    }).toList();

    final total = list.length;

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
      tasaOcupacion: tasaM2,
      ingresosMensualesProyectados: mrr,
      distribucionTiposEstado: distList,
      rentabilidadUbicacion: computedRentabilidad,
      rentaMensualBase: mrr,
      areaTotalRentable: totalArea,
      areaOcupada: areaRentada,
      areaVacante: areaVacante,
      rentaPromedioM2: rentaPromM2,
      rentaPotencialTotal: rentaPotencial,
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
