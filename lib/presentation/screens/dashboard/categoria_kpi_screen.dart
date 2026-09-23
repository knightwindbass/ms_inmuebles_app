import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/dashboard_kpi_model.dart';
import '../../../data/models/inmueble_model.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/inmuebles_repository.dart';
import '../../widgets/status_badge.dart';
import '../inmuebles/inmueble_detail_screen.dart';

/// Pantalla de KPIs focalizados por categoría comercial (Edificio, Bodega, Local, Oficina).
/// Presenta los KPIs de ocupación y flujo de caja en la parte superior,
/// y el listado de unidades correspondientes en la parte inferior.
class CategoriaKpiScreen extends StatefulWidget {
  final String tipo;

  const CategoriaKpiScreen({
    super.key,
    required this.tipo,
  });

  @override
  State<CategoriaKpiScreen> createState() => _CategoriaKpiScreenState();
}

class _CategoriaKpiScreenState extends State<CategoriaKpiScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardKpiModel? _kpis;
  List<InmuebleModel> _inmuebles = [];
  List<InmuebleModel> _filteredInmuebles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInmuebles = _inmuebles;
      } else {
        _filteredInmuebles = _inmuebles.where((item) {
          final matchNombre = item.nombre.toLowerCase().contains(query);
          final matchCiudad = (item.ciudad ?? '').toLowerCase().contains(query);
          final matchProv = (item.provincia ?? '').toLowerCase().contains(query);
          final matchDir = (item.direccion ?? '').toLowerCase().contains(query);
          final matchEstado = item.estado.toLowerCase().contains(query);
          return matchNombre || matchCiudad || matchProv || matchDir || matchEstado;
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashRepo = context.read<DashboardRepository>();
      final inmRepo = context.read<InmueblesRepository>();

      final results = await Future.wait([
        dashRepo.getResumen(tipo: widget.tipo),
        inmRepo.getInmuebles(tipo: widget.tipo),
      ]);

      final kpis = results[0] as DashboardKpiModel;
      final lista = results[1] as List<InmuebleModel>;

      if (!mounted) return;
      setState(() {
        _kpis = kpis;
        _inmuebles = lista;
        _filteredInmuebles = lista;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icon = AppTheme.getIconForType(widget.tipo);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Categoría · ${widget.tipo}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                'Error al consultar métricas de ${widget.tipo}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final kpis = _kpis;
    final int totalUnits = (kpis != null && kpis.inmuebles.total > 0)
        ? kpis.inmuebles.total
        : _inmuebles.length;

    // Calcular metraje real y rentas de la lista si los KPIs vinieron en 0
    final double computedArea = _inmuebles.fold(0.0, (sum, i) => sum + (i.metraje ?? 0.0));
    final double computedRenta = _inmuebles
        .where((i) => i.isRentado)
        .fold(0.0, (sum, i) => sum + i.valorRentaBase);

    final double effectiveArea = (kpis?.areaTotalRentable != null && kpis!.areaTotalRentable! > 0)
        ? kpis.areaTotalRentable!
        : computedArea;

    final double effectiveMrr = (kpis != null && kpis.ingresosMensualesProyectados > 0)
        ? kpis.ingresosMensualesProyectados
        : computedRenta;

    final double effectiveOcupacion = (kpis != null && kpis.tasaOcupacion > 0)
        ? kpis.tasaOcupacion
        : (_inmuebles.isNotEmpty
            ? (_inmuebles.where((i) => i.isRentado).length / _inmuebles.length) * 100
            : 0.0);

    final int rentadasCount = kpis?.inmuebles.rentados ?? _inmuebles.where((i) => i.isRentado).length;
    final int disponiblesCount = kpis?.inmuebles.disponibles ?? _inmuebles.where((i) => i.isDisponible).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. SMART KPIS DE LA CATEGORÍA
          _buildKpisGrid(
            totalUnits: totalUnits,
            ocupacion: effectiveOcupacion,
            areaM2: effectiveArea,
            mrr: effectiveMrr,
            rentadas: rentadasCount,
            disponibles: disponiblesCount,
            isDark: isDark,
          ),

          const SizedBox(height: 18),

          // 2. LISTADO DE INMUEBLES DE LA CATEGORÍA
          _buildInmueblesSection(isDark),
        ],
      ),
    );
  }

  Widget _buildKpisGrid({
    required int totalUnits,
    required double ocupacion,
    required double areaM2,
    required double mrr,
    required int rentadas,
    required int disponibles,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // 1. Unidades Totales
            Expanded(
              child: _buildMetricCard(
                title: 'Total Unidades',
                value: '$totalUnits',
                subtitle: '$rentadas rent / $disponibles disp',
                icon: Icons.meeting_room_rounded,
                accentColor: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // 2. Tasa de Ocupación
            Expanded(
              child: _buildMetricCard(
                title: 'Ocupación',
                value: AppFormatters.percentage(ocupacion),
                subtitle: '${ocupacion >= 80 ? "Alta" : "Regular"} demanda',
                icon: Icons.pie_chart_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 3. Área Total
            Expanded(
              child: _buildMetricCard(
                title: 'Área Total',
                value: AppFormatters.area(areaM2),
                subtitle: 'Superficie rentable',
                icon: Icons.square_foot_rounded,
                accentColor: const Color(0xFF06B6D4),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // 4. Ingreso Mensual (MRR)
            Expanded(
              child: _buildMetricCard(
                title: 'Facturación / mes',
                value: AppFormatters.currency(mrr),
                subtitle: 'MRR proyectado',
                icon: Icons.payments_rounded,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 2. Listado de Inmuebles Filtrados
  Widget _buildInmueblesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Unidades en Portafolio (${_filteredInmuebles.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Buscador
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar ${widget.tipo.toLowerCase()} por nombre o ubicación...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        if (_filteredInmuebles.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'No se encontraron unidades con esa búsqueda'
                    : 'No hay unidades de tipo ${widget.tipo} registradas',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          ..._filteredInmuebles.map((inmueble) => _buildInmuebleCard(inmueble, isDark)),
      ],
    );
  }

  Widget _buildInmuebleCard(InmuebleModel inmueble, bool isDark) {
    final location = [
      if (inmueble.ciudad != null && inmueble.ciudad!.isNotEmpty) inmueble.ciudad,
      if (inmueble.provincia != null && inmueble.provincia!.isNotEmpty) inmueble.provincia,
      if (inmueble.direccion != null && inmueble.direccion!.isNotEmpty) inmueble.direccion,
    ].join(' · ');

    final icon = AppTheme.getIconForType(inmueble.tipo);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InmuebleDetailScreen(
                inmuebleId: inmueble.id,
                inmuebleInitial: inmueble,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inmueble.nombre,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (inmueble.metraje != null && inmueble.metraje! > 0) ...[
                        const Icon(Icons.square_foot_rounded, size: 14, color: Color(0xFF06B6D4)),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.area(inmueble.metraje),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (inmueble.valorRentaBase > 0) ...[
                        const Icon(Icons.payments_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.currency(inmueble.valorRentaBase),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                  StatusBadge(status: inmueble.estado, isSmall: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
