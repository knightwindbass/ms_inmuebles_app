import 'package:flutter/material.dart';
import '../data/models/dashboard_kpi_model.dart';
import '../data/models/inmueble_model.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/inmuebles_repository.dart';

/// Proveedor de estado para el Dashboard de Inteligencia de Negocios y Reportes.
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;
  final InmueblesRepository? _inmueblesRepository;

  DashboardKpiModel? _kpis;
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedPadreId;

  DashboardProvider(this._repository, [this._inmueblesRepository]);

  DashboardKpiModel? get kpis => _kpis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedPadreId => _selectedPadreId;

  Future<void> fetchDashboard({int? padreId}) async {
    _selectedPadreId = padreId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Obtener la respuesta directa del endpoint del Dashboard
      final kpisResult = await _repository.getResumen(padreId: _selectedPadreId);

      _kpis = kpisResult;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 2. Fallback de contingencia si el endpoint falla: calcular desde /inmuebles
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

      if (isDispon) disp++;
      else if (isRent) {
        rent++;
        mrr += item.valorRentaBase;
      }
      else if (isMant) mant++;
      else if (isInac) inac++;

      // Jerarquía
      if (item.isSubunidad) {
        if (isInac) sInac++;
        else sAct++;
      } else {
        if (isInac) pInac++;
        else pAct++;
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
