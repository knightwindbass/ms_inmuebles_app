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
