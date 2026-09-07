import 'package:flutter/material.dart';
import '../data/models/inquilino_model.dart';
import '../data/repositories/inquilinos_repository.dart';

/// Proveedor de estado para el Directorio de Inquilinos con búsqueda instantánea en memoria.
class InquilinosProvider extends ChangeNotifier {
  final InquilinosRepository _repository;

  List<InquilinoModel> _todosLosInquilinos = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  InquilinosProvider(this._repository);

  List<InquilinoModel> get todosLosInquilinos => _todosLosInquilinos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // -------------------------------------------------------------
  // Lista filtrada en memoria (UX instantáneo en frontend)
  // -------------------------------------------------------------
  List<InquilinoModel> get inquilinosFiltrados {
    if (_searchQuery.isEmpty) return _todosLosInquilinos;

    final lowerQuery = _searchQuery.toLowerCase();
    return _todosLosInquilinos.where((inq) {
      final nombre = inq.nombresRazonSocial.toLowerCase();
      final id = inq.identificacion.toLowerCase();
      final tel = inq.telefono?.toLowerCase() ?? '';
      final email = inq.email?.toLowerCase() ?? '';

      return nombre.contains(lowerQuery) ||
          id.contains(lowerQuery) ||
          tel.contains(lowerQuery) ||
          email.contains(lowerQuery);
    }).toList();
  }

  // Métricas del Directorio
  int get totalClientes => _todosLosInquilinos.length;
  int get clientesActivos => _todosLosInquilinos.where((i) => i.isActivo).length;
  int get clientesInactivos => _todosLosInquilinos.where((i) => !i.isActivo).length;

  Future<void> fetchInquilinos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todosLosInquilinos = await _repository.getInquilinos();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra en memoria sin hacer llamadas HTTP repetidas al servidor
  void filtrarInquilinos(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}
