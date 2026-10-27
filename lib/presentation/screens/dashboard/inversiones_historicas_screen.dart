import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/inversion_historica_model.dart';
import '../../../logic/inversiones_provider.dart';
import '../../widgets/custom_search_bar.dart';

/// Pantalla completa ejecutiva para la consulta y simulación de Inversión Histórica de Proyectos.
class InversionesHistoricasScreen extends StatefulWidget {
  const InversionesHistoricasScreen({super.key});

  @override
  State<InversionesHistoricasScreen> createState() => _InversionesHistoricasScreenState();
}

class _InversionesHistoricasScreenState extends State<InversionesHistoricasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<InversionesProvider>(context, listen: false);
      if (provider.data == null && !provider.isLoading) {
        provider.fetchInversiones();
      }
    });
  }

  Color _getQualityColor(String quality) {
    final lower = quality.toLowerCase();
    if (lower.contains('alta')) return const Color(0xFF16A34A);
    if (lower.contains('superior')) return const Color(0xFF2563EB);
    if (lower.contains('intermedia')) return const Color(0xFFD97706);
    if (lower.contains('oficina')) return const Color(0xFF9333EA);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<InversionesProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Inversión Histórica',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar datos',
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: provider.isLoading && provider.data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Barra de Búsqueda por Proyecto, Inquilino o Ciudad
                  CustomSearchBar(
                    hintText: 'Buscar proyecto, inquilino o ciudad...',
                    initialValue: provider.searchQuery,
                    onSearch: (query) => provider.setSearchQuery(query),
                  ),

                  const SizedBox(height: 12),

                  // 2. Filtros Horizontales por Calidad
                  _buildQualityFilterBar(provider, isDark),

                  const SizedBox(height: 14),

                  // 3. 4 KPI Chips de Resumen Consolidado
                  if (provider.data != null)
                    _buildKpiSummaryRow(provider.data!.resumen, isDark),

                  const SizedBox(height: 16),

                  // 4. Conteo de Proyectos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${provider.filteredProyectos.length} Proyectos encontrados',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Corte: ${provider.data?.corteFecha ?? "26 oct 2026"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 5. Lista de Proyectos / Fichas
                  if (provider.filteredProyectos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron proyectos con el criterio ingresado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...provider.filteredProyectos.map(
                      (p) => _buildProjectCard(context, p, isDark),
                    ),

                  const SizedBox(height: 24),

                  // Nota de Metodología al Pie
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reglas de Cálculo y Auditoría:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Costo unitario / m² divide la construcción estrictamente entre el área de bodega techada.\n'
                          '• Los patios de maniobra (Pepsi Montalvo y Tonsupa) no se suman al denominador.\n'
                          '• Los indicadores unitarios excluyen gastos financieros de acuerdo al estándar de valuación.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildQualityFilterBar(InversionesProvider provider, bool isDark) {
    final filters = [
      {'label': 'Todas', 'val': 'all'},
      {'label': 'Alta (9.5)', 'val': 'Alta'},
      {'label': 'Superior (8.5)', 'val': 'Superior'},
      {'label': 'Intermedia (7.5–7.9)', 'val': 'Intermedia'},
      {'label': 'Básica (6.8)', 'val': 'Básica'},
      {'label': 'Oficinas', 'val': 'Oficinas'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = filters[i];
          final isSelected = provider.selectedQuality == item['val'];
          return ChoiceChip(
            label: Text(item['label']!),
            selected: isSelected,
            onSelected: (_) => provider.setSelectedQuality(item['val']!),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
            selectedColor: const Color(0xFF0D9488),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF0D9488)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiSummaryRow(InversionesResumenModel resumen, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniKpi(
                title: 'Construcción histórica',
                value: AppFormatters.compactCurrency(resumen.construccionTotal),
                exactVal: AppFormatters.currency(resumen.construccionTotal),
                color: const Color(0xFF0D9488),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniKpi(
                title: 'Terrenos y gastos',
                value: AppFormatters.compactCurrency(resumen.terrenosTotal),
                exactVal: AppFormatters.currency(resumen.terrenosTotal),
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMiniKpi(
                title: 'Inversión total',
                value: AppFormatters.compactCurrency(resumen.inversionTotal),
                exactVal: AppFormatters.currency(resumen.inversionTotal),
                color: const Color(0xFF0F172A),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniKpi(
                title: 'Gastos financieros reg.',
                value: AppFormatters.compactCurrency(resumen.financierosTotal),
                exactVal: AppFormatters.currency(resumen.financierosTotal),
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniKpi({
    required String title,
    required String value,
    required String exactVal,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Text(
            exactVal,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, InversionProyectoModel p, bool isDark) {
    const colorTeal = Color(0xFF0D9488);
    final qualityColor = _getQualityColor(p.categoriaCalidad);
    final costConstStr = p.costoM2Construccion != null
        ? '${AppFormatters.currency(p.costoM2Construccion)} / m²'
        : 'Área pendiente';
    final costHardStr = p.costoM2ConTierra != null
        ? '${AppFormatters.currency(p.costoM2ConTierra)} / m²'
        : 'Área pendiente';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Nombre y Badge de Calidad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${p.periodo}${p.ciudad.isNotEmpty ? " • ${p.ciudad}" : ""}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: qualityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: qualityColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    p.calificacion != null
                        ? '${p.categoriaCalidad} • ${p.calificacion}/10'
                        : p.categoriaCalidad,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: qualityColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hero Metric Box: Construcción sin Tierra / m²
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F2E2B) : const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CONSTRUCCIÓN SIN TIERRA / m² DE BODEGA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    costConstStr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F766E),
                    ),
                  ),
                  Text(
                    'Construcción: ${AppFormatters.currency(p.construccion)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Hard Costs Box (Construcción + Tierra)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Construcción + Tierra:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    costHardStr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Desglose de Área y Terreno
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terreno y directos: ${AppFormatters.compactCurrency(p.terreno)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Bodega: ${p.areaBodega != null ? AppFormatters.number(p.areaBodega) + " m²" : "Pendiente"}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            // Alerta informativa si tiene Patio segregado
            if (p.areaPatio != null && p.areaPatio! > 0) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF78350F) : const Color(0xFFFFEDD5),
                  ),
                ),
                child: Text(
                  'Patio segregado: ${AppFormatters.number(p.areaPatio)} m² (${p.patioRatio?.toStringAsFixed(2) ?? "–"} patio/bodega)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botón Simular Área
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Simular Área / Ver Desglose'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorTeal,
                  side: const BorderSide(color: colorTeal),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showAreaSimulationSheet(context, p, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAreaSimulationSheet(BuildContext context, InversionProyectoModel p, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AreaSimulationBottomSheet(project: p, isDark: isDark);
      },
    );
  }
}

/// Bottom Sheet Interactivo para simular área y ver ficha de desglose
class _AreaSimulationBottomSheet extends StatefulWidget {
  final InversionProyectoModel project;
  final bool isDark;

  const _AreaSimulationBottomSheet({
    required this.project,
    required this.isDark,
  });

  @override
  State<_AreaSimulationBottomSheet> createState() => _AreaSimulationBottomSheetState();
}

class _AreaSimulationBottomSheetState extends State<_AreaSimulationBottomSheet> {
  late final TextEditingController _areaCtrl;
  double _currentArea = 0.0;

  @override
  void initState() {
    super.initState();
    _currentArea = widget.project.areaBodega ?? 10000.0;
    _areaCtrl = TextEditingController(text: _currentArea.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final isDark = widget.isDark;
    const colorTeal = Color(0xFF0D9488);

    final simConst = p.simularCostoConstruccion(_currentArea);
    final simHard = p.simularCostoConTierra(_currentArea);
    final simLand = _currentArea > 0 ? (p.terreno / _currentArea) : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            'Simulador de costo unitario por m² de bodega',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Campo de Entrada para simular
          TextField(
            controller: _areaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              setState(() {
                _currentArea = parsed;
              });
            },
            decoration: InputDecoration(
              labelText: 'Superficie para simular (m²)',
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              suffixText: 'm²',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 16),

          // Resultados Recalculados en Tiempo Real
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2E2B) : const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'SOLO CONSTRUCCIÓN PROYECTADA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  simConst != null ? '${AppFormatters.currency(simConst)} / m²' : 'Pendiente',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F766E),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Construcción + Tierra:', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    Text(simHard != null ? '${AppFormatters.currency(simHard)} / m²' : '–', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Incidencia Terreno:', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    Text('${AppFormatters.currency(simLand)} / m²', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (p.areaBodega != null && (_currentArea - p.areaBodega!).abs() > 1.0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '⚡ Superficie simulada diferente al registro base (${p.areaBodega} m²).',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
