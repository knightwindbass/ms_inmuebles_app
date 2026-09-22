import 'package:flutter/material.dart';
import '../data/models/inmueble_model.dart';
import '../data/repositories/inmuebles_repository.dart';

/// Proveedor de estado para el inventario y motor de búsqueda de Inmuebles.
class InmueblesProvider extends ChangeNotifier {
  final InmueblesRepository _repository;

  List<InmuebleModel> _inmuebles = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filtros activos
  String? _selectedEstado;
  String? _selectedTipo;
  String _searchQuery = '';
  String? _selectedPropietario;
  String? _selectedOrden;
  int? _selectedPadreId;

  InmueblesProvider(this._repository);

  List<InmuebleModel> get inmuebles => _inmuebles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedEstado => _selectedEstado;
  String? get selectedTipo => _selectedTipo;
  String get searchQuery => _searchQuery;
  String? get selectedPropietario => _selectedPropietario;
  String? get selectedOrden => _selectedOrden;
  int? get selectedPadreId => _selectedPadreId;

  /// Determina si el usuario está realizando una búsqueda o aplicando filtros
  bool get hasFilters =>
      _searchQuery.isNotEmpty ||
      (_selectedEstado != null && _selectedEstado!.isNotEmpty) ||
      (_selectedTipo != null && _selectedTipo!.isNotEmpty) ||
      (_selectedPropietario != null && _selectedPropietario!.isNotEmpty);

  /// Lista de nivel superior para renderizar en el ListView
  /// Si hay filtros activos, se devuelve una vista PLANA para que ningún resultado quede oculto.
  /// Si no hay filtros, devuelve únicamente las propiedades Matriz / Principales.
  List<InmuebleModel> get topLevelInmuebles {
    if (hasFilters) {
      return _inmuebles;
    }

    final top = _inmuebles.where((item) {
      return item.propiedadPadreId == null || item.propiedadPadreId == 0;
    }).toList();

    // Si por alguna razón todos tienen padre (no hay matrices raíz), mostrar lista completa
    return top.isNotEmpty ? top : _inmuebles;
  }

  /// Mapa de sub-unidades agrupadas por el ID de la propiedad matriz padre
  Map<int, List<InmuebleModel>> get groupedChildren {
    final Map<int, List<InmuebleModel>> map = {};
    if (hasFilters) return map;

    for (final item in _inmuebles) {
      if (item.propiedadPadreId != null && item.propiedadPadreId! > 0) {
        final pId = item.propiedadPadreId!;
        map.putIfAbsent(pId, () => []).add(item);
      }
    }
    return map;
  }

  // -------------------------------------------------------------
  // Métricas y Totales de Auditoría para Cuadre Financiero
  // -------------------------------------------------------------

  /// Conteo de inmuebles en estado 'rentado' en la lista actual
  int get totalRentados => _inmuebles.where((i) => i.isRentado).length;

  /// Conteo de inmuebles en estado 'disponible' en la lista actual
  int get totalDisponibles => _inmuebles.where((i) => i.isDisponible).length;

  /// Conteo de inmuebles en otros estados (mantenimiento / inactivo)
  int get totalOtrosEstados => _inmuebles.where((i) => !i.isRentado && !i.isDisponible).length;

  /// Suma de área total (m²) de la lista actual.
  /// Si no hay filtros, calcula sobre unidades leasables para evitar duplicar matrices complejas.
  double get totalAreaAudit {
    if (hasFilters) {
      return _inmuebles.fold(0.0, (sum, i) => sum + (i.metraje ?? 0.0));
    }
    final parentIds = _inmuebles
        .map((e) => e.propiedadPadreId)
        .where((id) => id != null && id > 0)
        .toSet();
    final leasables = _inmuebles.where((e) => !parentIds.contains(e.id));
    return leasables.fold(0.0, (sum, i) => sum + (i.metraje ?? 0.0));
  }

  /// Suma total de m² de todas las filas individuales sin excluir matrices
  double get totalAreaFilasBrutas {
    return _inmuebles.fold(0.0, (sum, i) => sum + (i.metraje ?? 0.0));
  }

  /// Suma total del valor de renta de los inmuebles rentados en la lista actual
  double get totalRentaRentados {
    return _inmuebles.where((i) => i.isRentado).fold(0.0, (sum, i) => sum + i.valorRentaBase);
  }

  /// Suma total de cánones base de todos los inmuebles de la lista actual (rentados + disponibles)
  double get totalRentaBasePortafolio {
    return _inmuebles.fold(0.0, (sum, i) => sum + i.valorRentaBase);
  }

  /// Área total de los inmuebles rentados (para cálculo de $/m² de auditoría)
  double get areaRentadaAudit {
    return _inmuebles.where((i) => i.isRentado).fold(0.0, (sum, i) => sum + (i.metraje ?? 0.0));
  }

  /// Valor promedio ponderado $/m² de los inmuebles rentados
  double get valorPromedioM2Audit {
    final area = areaRentadaAudit;
    final renta = totalRentaRentados;
    return area > 0 ? (renta / area) : 0.0;
  }

  /// Resumen textual de los filtros aplicados
  String get resumenFiltrosActivos {
    final List<String> parts = [];
    if (_searchQuery.isNotEmpty) parts.add('Búsqueda: "$_searchQuery"');
    if (_selectedEstado != null && _selectedEstado!.isNotEmpty) parts.add('Estado: $_selectedEstado');
    if (_selectedTipo != null && _selectedTipo!.isNotEmpty) parts.add('Tipo: $_selectedTipo');
    if (_selectedPropietario != null && _selectedPropietario!.isNotEmpty) parts.add('Prop: $_selectedPropietario');
    return parts.isEmpty ? 'Sin filtros' : parts.join(' • ');
  }

  Future<void> fetchInmuebles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inmuebles = await _repository.getInmuebles(
        estado: _selectedEstado,
        tipo: _selectedTipo,
        buscar: _searchQuery.isNotEmpty ? _searchQuery : null,
        propietario: _selectedPropietario,
        padreId: _selectedPadreId,
        orden: _selectedOrden,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEstadoFilter(String? estado) {
    if (_selectedEstado == estado) {
      _selectedEstado = null;
    } else {
      _selectedEstado = estado;
    }
    fetchInmuebles();
  }

  void setTipoFilter(String? tipo) {
    if (_selectedTipo == tipo) {
      _selectedTipo = null;
    } else {
      _selectedTipo = tipo;
    }
    fetchInmuebles();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    fetchInmuebles();
  }

  void setOrden(String? orden) {
    _selectedOrden = orden;
    fetchInmuebles();
  }

  void setPropietario(String? propietario) {
    _selectedPropietario = propietario;
    fetchInmuebles();
  }

  void clearFilters() {
    _selectedEstado = null;
    _selectedTipo = null;
    _searchQuery = '';
    _selectedPropietario = null;
    _selectedOrden = null;
    _selectedPadreId = null;
    fetchInmuebles();
  }

  Future<InmuebleModel?> getDetalle(int id) async {
    try {
      return await _repository.getInmuebleDetalle(id);
    } catch (e) {
      return null;
    }
  }
}
