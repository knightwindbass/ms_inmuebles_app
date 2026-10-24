import 'package:flutter/material.dart';
import '../data/models/deuda_inmobiliaria_model.dart';
import '../data/repositories/deuda_repository.dart';

/// Proveedor de estado para la gestión de pasivos y riesgos inmobiliarios.
class DeudaProvider extends ChangeNotifier {
  final DeudaRepository _repository;

  DeudaDashboardModel? _deudaDashboard;
  bool _isLoading = false;
  String? _errorMessage;

  DeudaProvider(this._repository);

  DeudaDashboardModel? get deudaDashboard => _deudaDashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene los datos consolidados de deuda inmobiliaria
  Future<void> fetchDeudaDashboard({bool forceRefresh = false}) async {
    if (!forceRefresh && _deudaDashboard != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getDeudaDashboard();
      _deudaDashboard = data;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga los datos forzadamente
  Future<void> refresh() async {
    await fetchDeudaDashboard(forceRefresh: true);
  }
}
