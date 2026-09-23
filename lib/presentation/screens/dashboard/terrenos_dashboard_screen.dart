import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/dashboard_kpi_model.dart';
import '../../../data/models/inmueble_model.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/inmuebles_repository.dart';
import '../../widgets/status_badge.dart';
import '../inmuebles/inmueble_detail_screen.dart';

/// Pantalla especializada para Land Banking (Banco de Tierras y Terrenos).
/// Aísla métricas de tenencia territorial (Volumen, Fideicomisos, Reserva m²)
/// y no incluye métricas de flujo de caja comercial (MRR ni rentabilidad).
class TerrenosDashboardScreen extends StatefulWidget {
  const TerrenosDashboardScreen({super.key});

  @override
  State<TerrenosDashboardScreen> createState() => _TerrenosDashboardScreenState();
}

class _TerrenosDashboardScreenState extends State<TerrenosDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardKpiModel? _kpis;
  List<InmuebleModel> _terrenos = [];
  List<InmuebleModel> _filteredTerrenos = [];
  final TextEditingController _searchController = TextEditingController();
  int _touchedIndex = -1;
  bool _isAreaMode = false;

  // Paleta de colores oficial para Land Banking
  static const Color colorDisponible = Color(0xFF3B82F6); // Azul
  static const Color colorAportado = Color(0xFF8B5CF6); // Morado
  static const Color colorCrudo = Color(0xFF06B6D4); // Cian / Celeste
  static const Color colorEnDesarrollo = Color(0xFF10B981); // Verde

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
        _filteredTerrenos = _terrenos;
      } else {
        _filteredTerrenos = _terrenos.where((t) {
          final matchNombre = t.nombre.toLowerCase().contains(query);
          final matchCiudad = (t.ciudad ?? '').toLowerCase().contains(query);
          final matchProv = (t.provincia ?? '').toLowerCase().contains(query);
          final matchEstado = t.estado.toLowerCase().contains(query);
          return matchNombre || matchCiudad || matchProv || matchEstado;
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
        dashRepo.getResumen(tipo: 'Terreno'),
        inmRepo.getInmuebles(tipo: 'Terreno'),
      ]);

      final kpis = results[0] as DashboardKpiModel;
      final lista = results[1] as List<InmuebleModel>;

      if (!mounted) return;
      setState(() {
        _kpis = kpis;
        _terrenos = lista;
        _filteredTerrenos = lista;
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.landscape_rounded, color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Land Banking · Terrenos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                'Error al consultar Land Banking',
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
    if (kpis == null) {
      return const Center(child: Text('No hay información de terrenos disponible'));
    }

    final desglose = kpis.inmuebles;
    final int volumenTotal = desglose.total > 0 ? desglose.total : _terrenos.length;
    final int aportados = desglose.aportados;
    final double areaM2 = desglose.areaTotal > 0
        ? desglose.areaTotal
        : _terrenos.fold(0.0, (sum, t) => sum + (t.metraje ?? 0.0));
    final double totalAreaTerrenos = _terrenos.fold(0.0, (sum, t) => sum + (t.metraje ?? 0.0));
    final double totalValorTerrenos = desglose.valorTotal > 0
        ? desglose.valorTotal
        : _terrenos.fold(0.0, (sum, t) => sum + t.valorRentaBase);
    final double valorM2Promedio = desglose.valorM2Promedio > 0
        ? desglose.valorM2Promedio
        : (totalAreaTerrenos > 0 ? (totalValorTerrenos / totalAreaTerrenos) : 0.0);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. CUATRO TARJETAS PRINCIPALES DE LAND BANKING (GRID 2x2)
          _buildKpiCards(volumenTotal, aportados, areaM2, valorM2Promedio, isDark),

          const SizedBox(height: 12),

          // 2. TARJETA DE ANCHO COMPLETO: VALOR REFERENCIAL TOTAL ($)
          _buildValorReferencialTotalCard(totalValorTerrenos, valorM2Promedio, isDark),

          const SizedBox(height: 18),

          // 3. GRÁFICO DE DONA: ESTADO DEL BANCO DE TIERRAS (Lotes o Área m²)
          _buildDonutChartCard(desglose, volumenTotal, isDark),

          const SizedBox(height: 20),

          // 4. SECCIÓN DE INVENTARIO DE TERRENOS
          _buildTerrenosSection(isDark),
        ],
      ),
    );
  }

  /// 1. Tarjetas de KPIs Principales de Terrenos (Grid 2x2)
  Widget _buildKpiCards(int volumenTotal, int aportados, double areaM2, double valorM2Promedio, bool isDark) {
    final valorM2Str = valorM2Promedio > 0 ? '\$${valorM2Promedio.toStringAsFixed(2)} / m²' : '-';

    return Column(
      children: [
        Row(
          children: [
            // 1. Tarjeta: Volumen Total
            Expanded(
              child: _buildMetricCard(
                title: 'Volumen Total',
                value: '$volumenTotal',
                subtitle: 'Lotes registrados',
                icon: Icons.layers_rounded,
                accentColor: colorDisponible,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // 2. Tarjeta: Aportados en Fideicomiso
            Expanded(
              child: _buildMetricCard(
                title: 'Fideicomisos',
                value: '$aportados',
                subtitle: 'Tierra aportada',
                icon: Icons.account_balance_rounded,
                accentColor: colorAportado,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 3. Tarjeta: Reserva Territorial
            Expanded(
              child: _buildMetricCard(
                title: 'Reserva Territorial',
                value: AppFormatters.area(areaM2),
                subtitle: 'Superficie total',
                icon: Icons.square_foot_rounded,
                accentColor: colorCrudo,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // 4. Tarjeta: Valor m² Promedio
            Expanded(
              child: _buildMetricCard(
                title: 'Valor m² Promedio',
                value: valorM2Str,
                subtitle: 'Promedio portafolio',
                icon: Icons.monetization_on_outlined,
                accentColor: colorEnDesarrollo,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
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
              fontSize: 16,
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
              fontSize: 10,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 2. Tarjeta de Valor Referencial Total de Terrenos (ancho completo, 2 columnas)
  Widget _buildValorReferencialTotalCard(double totalValor, double valorM2Promedio, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono distinguido con gradiente esmeralda
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Información y Montos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valor Referencial Total',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Avalúo Portafolio',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  AppFormatters.currency(totalValor),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  valorM2Promedio > 0
                      ? 'Valuación base de la reserva (${AppFormatters.currency(valorM2Promedio)} / m² prom.)'
                      : 'Valuación base total de la reserva territorial',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Gráfico de Dona: Estado del Desarrollo del Banco de Tierras (Lotes o Área m²)
  Widget _buildDonutChartCard(InmueblesDesglose desglose, int volumenTotal, bool isDark) {
    // 1. Conteo por Lotes (unidades)
    double cntDisponible = desglose.disponibles.toDouble();
    double cntAportado = desglose.aportados.toDouble();
    double cntCrudo = desglose.disponibleSinRellenar.toDouble();
    double cntEnDesarrollo = desglose.enDesarrollo.toDouble();

    if (cntDisponible == 0 && cntAportado == 0 && cntCrudo == 0 && cntEnDesarrollo == 0) {
      for (final t in _terrenos) {
        final est = t.estado.toLowerCase().trim();
        if (est.contains('aportad') || est.contains('fideicomiso')) {
          cntAportado++;
        } else if (est.contains('sin rellenar') || est.contains('sin_rellenar') || est.contains('crudo')) {
          cntCrudo++;
        } else if (est.contains('en desarrollo') || est.contains('en_desarrollo') || est.contains('rellenado')) {
          cntEnDesarrollo++;
        } else {
          cntDisponible++;
        }
      }
    }

    // 2. Distribución por Área (m²)
    double areaDisponible = 0.0;
    double areaAportado = 0.0;
    double areaCrudo = 0.0;
    double areaEnDesarrollo = 0.0;

    for (final t in _terrenos) {
      final m = t.metraje ?? 0.0;
      final est = t.estado.toLowerCase().trim();
      if (est.contains('aportad') || est.contains('fideicomiso')) {
        areaAportado += m;
      } else if (est.contains('sin rellenar') || est.contains('sin_rellenar') || est.contains('crudo')) {
        areaCrudo += m;
      } else if (est.contains('en desarrollo') || est.contains('en_desarrollo') || est.contains('rellenado')) {
        areaEnDesarrollo += m;
      } else {
        areaDisponible += m;
      }
    }

    final bool isArea = _isAreaMode;
    final double valDisp = isArea ? areaDisponible : cntDisponible;
    final double valAport = isArea ? areaAportado : cntAportado;
    final double valCrudo = isArea ? areaCrudo : cntCrudo;
    final double valDesarr = isArea ? areaEnDesarrollo : cntEnDesarrollo;

    final double sumTotal = valDisp + valAport + valCrudo + valDesarr;
    final bool hasData = sumTotal > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pie_chart_rounded, size: 18, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    Text(
                      'Distribución Territorial',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                // Selector de Modo: Por Lotes vs Por Área m²
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChartToggleItem(
                        label: 'Lotes',
                        isSelected: !_isAreaMode,
                        onTap: () {
                          if (_isAreaMode) {
                            setState(() {
                              _isAreaMode = false;
                              _touchedIndex = -1;
                            });
                          }
                        },
                        isDark: isDark,
                      ),
                      _buildChartToggleItem(
                        label: 'Área m²',
                        isSelected: _isAreaMode,
                        onTap: () {
                          if (!_isAreaMode) {
                            setState(() {
                              _isAreaMode = true;
                              _touchedIndex = -1;
                            });
                          }
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasData)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    isArea
                        ? 'No hay registro de áreas en los terrenos'
                        : 'No hay registro de estados en los terrenos',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else ...[
              // Dona Central Interactiva
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 52,
                        sections: _buildChartSections(
                          valDisp,
                          valAport,
                          valCrudo,
                          valDesarr,
                          sumTotal,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArea ? AppFormatters.area(sumTotal) : '${sumTotal.toInt()}',
                          style: TextStyle(
                            fontSize: isArea ? 15 : 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          isArea ? 'Superficie' : 'Lotes',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Leyenda con porcentajes y cantidades
              _buildLegend(
                valDisponible: valDisp,
                valAportado: valAport,
                valCrudo: valCrudo,
                valEnDesarrollo: valDesarr,
                total: sumTotal,
                isArea: isArea,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(
    double valDisp,
    double valAport,
    double valCrudo,
    double valDesarr,
    double total,
  ) {
    final List<PieChartSectionData> sections = [];
    int idx = 0;

    void addSection(double val, Color color) {
      if (val > 0) {
        final isTouched = idx == _touchedIndex;
        final radius = isTouched ? 38.0 : 32.0;
        final pct = (val / total * 100).toStringAsFixed(0);
        sections.add(
          PieChartSectionData(
            color: color,
            value: val,
            title: '$pct%',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
        idx++;
      }
    }

    addSection(valDisp, colorDisponible);
    addSection(valAport, colorAportado);
    addSection(valCrudo, colorCrudo);
    addSection(valDesarr, colorEnDesarrollo);

    return sections;
  }

  Widget _buildLegend({
    required double valDisponible,
    required double valAportado,
    required double valCrudo,
    required double valEnDesarrollo,
    required double total,
    required bool isArea,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                label: 'Disponible (Listo desarrollo)',
                value: valDisponible,
                total: total,
                isArea: isArea,
                color: colorDisponible,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLegendItem(
                label: 'Aportado (Fideicomiso)',
                value: valAportado,
                total: total,
                isArea: isArea,
                color: colorAportado,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                label: 'Sin Rellenar (Crudo)',
                value: valCrudo,
                total: total,
                isArea: isArea,
                color: colorCrudo,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLegendItem(
                label: 'En Desarrollo / Rellenado',
                value: valEnDesarrollo,
                total: total,
                isArea: isArea,
                color: colorEnDesarrollo,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required String label,
    required double value,
    required double total,
    required bool isArea,
    required Color color,
    required bool isDark,
  }) {
    final pct = total > 0 ? ((value / total) * 100).toStringAsFixed(1) : '0';
    final valueSubtitle = isArea
        ? '${AppFormatters.area(value)} ($pct%)'
        : '${value.toInt()} lote${value.toInt() == 1 ? '' : 's'} ($pct%)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  valueSubtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Listado de Terrenos con Buscador y Estados Individuales
  Widget _buildTerrenosSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inventario de Terrenos (${_filteredTerrenos.length})',
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
            hintText: 'Buscar lote por nombre o ubicación...',
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
        if (_filteredTerrenos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'No se encontraron lotes con esa búsqueda'
                    : 'No hay terrenos registrados en el inventario',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          ..._filteredTerrenos.map((terreno) => _buildTerrenoCard(terreno, isDark)),
      ],
    );
  }

  Widget _buildTerrenoCard(InmuebleModel terreno, bool isDark) {
    final location = [
      if (terreno.provincia != null && terreno.provincia!.isNotEmpty) terreno.provincia,
      if (terreno.ciudad != null && terreno.ciudad!.isNotEmpty) terreno.ciudad,
      if (terreno.direccion != null && terreno.direccion!.isNotEmpty) terreno.direccion,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InmuebleDetailScreen(
                inmuebleId: terreno.id,
                inmuebleInitial: terreno,
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
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.terrain_rounded, color: Color(0xFF3B82F6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          terreno.nombre,
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
                      const Icon(Icons.square_foot_rounded, size: 14, color: Color(0xFF06B6D4)),
                      const SizedBox(width: 4),
                      Text(
                        'Superficie: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        AppFormatters.area(terreno.metraje),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: terreno.estado, isSmall: true),
                ],
              ),
              if (terreno.valorM2 > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on_outlined,
                            size: 13,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Valor m²: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            '\$${terreno.valorM2.toStringAsFixed(2)} / m²',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (terreno.valorRentaBase > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valuación: ${AppFormatters.currency(terreno.valorRentaBase)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
