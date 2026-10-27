import 'package:flutter/material.dart';
import '../data/models/inversion_historica_model.dart';
import '../data/repositories/inversiones_repository.dart';

/// Proveedor de estado para la visualización y análisis de Inversión Histórica de Proyectos.
class InversionesProvider extends ChangeNotifier {
  final InversionesRepository _repository;

  InversionesHistoricasResponse? _data;
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedQuality = 'all';

  InversionesProvider(this._repository);

  InversionesHistoricasResponse? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedQuality => _selectedQuality;

  /// Obtiene los datos consolidados de inversiones históricas
  Future<void> fetchInversiones({bool forceRefresh = false}) async {
    if (!forceRefresh && _data != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getInversionesHistoricas();
      _data = res;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga forzada de los datos
  Future<void> refresh() async {
    await fetchInversiones(forceRefresh: true);
  }

  /// Filtro de búsqueda textual por proyecto, inquilino o ciudad
  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  /// Filtro por categoría de calidad
  void setSelectedQuality(String quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  /// Proyectos filtrados dinámicamente según la barra de búsqueda y la categoría
  List<InversionProyectoModel> get filteredProyectos {
    if (_data == null) return [];
    return _data!.proyectos.where((p) {
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.inquilino.toLowerCase().contains(_searchQuery) ||
          p.ciudad.toLowerCase().contains(_searchQuery);

      final matchQuality = _selectedQuality == 'all' ||
          p.categoriaCalidad.toLowerCase().contains(_selectedQuality.toLowerCase());

      return matchSearch && matchQuality;
    }).toList();
  }
}
