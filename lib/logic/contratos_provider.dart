import 'package:flutter/material.dart';
import '../data/models/contrato_model.dart';
import '../data/repositories/contratos_repository.dart';

/// Proveedor de estado para el módulo de contratos, con cálculo en tiempo real de MRR y Alertas de Vencimiento.
class ContratosProvider extends ChangeNotifier {
  final ContratosRepository _repository;

  List<ContratoModel> _contratos = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedOrden = 'vencimiento_asc'; // Por defecto: Próximos a vencer

  ContratosProvider(this._repository);

  List<ContratoModel> get contratos => _contratos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedOrden => _selectedOrden;

  // -------------------------------------------------------------
  // KPIs Dinámicos Calculados en Frontend sobre los resultados
  // -------------------------------------------------------------

  /// Total de contratos únicos con estado 'vigente' acorde al ID
  int get totalActivos {
    return _contratos.where((c) => c.isVigente).length;
  }

  /// Ingreso Recurrente Mensual (MRR) normalizando frecuencias anuales sobre montos acumulados
  double get mrr {
    double total = 0.0;
    for (final c in _contratos) {
      if (c.isVigente) {
        total += c.valorMensualizado;
      }
    }
    return total;
  }

  /// Cantidad de contratos vigentes que vencen en 60 días o menos (Alerta de Renovación)
  int get porVencer {
    int count = 0;
    for (final c in _contratos) {
      if (c.isVigente) {
        final dias = c.diasRestantes;
        if (dias > 0 && dias <= 60) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> fetchContratos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.getContratos(
        buscar: _searchQuery.isNotEmpty ? _searchQuery : null,
        orden: _selectedOrden,
      );
      _sortContratos(fetched);
      _contratos = fetched;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortContratos(List<ContratoModel> list) {
    switch (_selectedOrden) {
      case 'vencimiento_asc':
        list.sort((a, b) => a.fechaFin.compareTo(b.fechaFin));
        break;
      case 'vencimiento_desc':
        list.sort((a, b) => b.fechaFin.compareTo(a.fechaFin));
        break;
      case 'monto_desc':
        list.sort((a, b) => b.valorPactado.compareTo(a.valorPactado));
        break;
      case 'monto_asc':
        list.sort((a, b) => a.valorPactado.compareTo(b.valorPactado));
        break;
      case 'inquilino_asc':
        list.sort((a, b) => a.nombresInquilino.toLowerCase().compareTo(b.nombresInquilino.toLowerCase()));
        break;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    fetchContratos();
  }

  void setOrden(String orden) {
    _selectedOrden = orden;
    fetchContratos();
  }

  ContratoModel? findContratoById(int id) {
    try {
      return _contratos.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ContratoModel?> getDetalle(int id) async {
    final cached = findContratoById(id);
    try {
      final remote = await _repository.getContratoDetalle(id);
      if (cached != null && cached.tieneMultiplesInmuebles) {
        return cached.mergeWith(remote);
      }
      return remote;
    } catch (e) {
      return cached;
    }
  }
}
