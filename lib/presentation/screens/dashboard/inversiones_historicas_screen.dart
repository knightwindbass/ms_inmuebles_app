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
  static const Color colorTeal = Color(0xFF0D9488);
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
    final qualityColor = _getQualityColor(p.categoriaCalidad);
    final mainCostStr = p.costoM2Principal != null
        ? '${AppFormatters.currency(p.costoM2Principal)} / m²'
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
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
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
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.periodo}${p.ciudad.isNotEmpty ? " · ${p.ciudad}" : ""}',
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
                        ? '${p.categoriaCalidad} · ${p.calificacion}/10'
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

            // Hero Metric Box: Costo por m² de Bodega (Limpia, sin códigos de fórmulas)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFF2DD4BF) : colorTeal,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'COSTO POR M² DE BODEGA',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mainCostStr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F766E),
                    ),
                  ),
                  Text(
                    'Inversión Total: ${AppFormatters.currency(p.totalInvertido)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Campo de Observaciones de Obra / Notas del Proyecto (Método de Cálculo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: isDark ? const Color(0xFF2DD4BF) : colorTeal,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'OBSERVACIONES DEL PROYECTO',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.nota.isNotEmpty ? p.nota : 'Sin observaciones de obra registradas.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      fontStyle: p.nota.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      color: p.nota.isNotEmpty
                          ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Resumen Rápido: Terreno, Construcción y Bodega
            // 3 Columnas: Terreno, Construcción y Bodega (Título arriba, valor abajo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  // Columna 1: Terreno
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'TERRENO',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.compactCurrency(p.terreno),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  // Columna 2: Construcción
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'CONSTRUCCIÓN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.compactCurrency(p.construccion),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  // Columna 3: Bodega
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'BODEGA',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.areaBodega != null ? '${AppFormatters.number(p.areaBodega)} m²' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF2DD4BF) : colorTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                  'Patio segregado: ${AppFormatters.number(p.areaPatio)} m² (${p.patioRatio?.toStringAsFixed(2) ?? "—"} patio/bodega)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botón Ver Desglose de Inversión y Área
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text('Ver Desglose de Inversión y Área'),
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

/// Bottom Sheet Completo: Desglose de Inversión y Área (Ficha Histórica)
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
  static const Color colorTeal = Color(0xFF0D9488);

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

  Color _getQualityColor(String quality) {
    final lower = quality.toLowerCase();
    if (lower.contains('alta')) return const Color(0xFF16A34A);
    if (lower.contains('superior')) return const Color(0xFF2563EB);
    if (lower.contains('intermedia')) return const Color(0xFFD97706);
    if (lower.contains('oficinas')) return const Color(0xFF9333EA);
    return const Color(0xFF64748B);
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: isDark ? const Color(0xFF2DD4BF) : colorTeal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isBold = false, Color? valColor, bool highlight = false, String? note, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: highlight ? 8 : 6),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark ? const Color(0xFF0F2E2B) : const Color(0xFFF0FDFA))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? (isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final isDark = widget.isDark;

    final double hardCosts = p.terreno + p.construccion;
    final double totalInvested = p.totalInvertido;
    final double? bodegaArea = p.areaBodega;
    final double? patioArea = p.areaPatio;
    final double totalArea = p.areaTotal ?? ((bodegaArea ?? 0.0) + (patioArea ?? 0.0));
    final double? mainCost = p.costoM2Principal;

    // Simulación interactiva de superficie
    final double? simPrincipal = p.simularCostoPrincipal(_currentArea);
    final double? simConstruccion = _currentArea > 0 ? (p.construccion / _currentArea) : null;
    final double? simHard = _currentArea > 0 ? (hardCosts / _currentArea) : null;
    final double? simTotal = _currentArea > 0 ? (totalInvested / _currentArea) : null;

    final Color qualityColor = _getQualityColor(p.categoriaCalidad);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ficha Histórica · Desglose de Inversión y Área',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF2DD4BF) : colorTeal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: qualityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: qualityColor.withOpacity(0.3)),
                ),
                child: Text(
                  p.calificacion != null
                      ? '${p.categoriaCalidad} · ${p.calificacion}/10'
                      : p.categoriaCalidad,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: qualityColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DESGLOSE DE INVERSIÓN
                  _buildSectionTitle('DESGLOSE DE INVERSIÓN (VALORES FINANCIEROS)', Icons.attach_money_rounded, isDark),
                  _buildDataRow('Inversión en Terreno y directos:', AppFormatters.currency(p.terreno), isDark: isDark),
                  _buildDataRow('Inversión en Construcción (Obras civiles):', AppFormatters.currency(p.construccion), isDark: isDark),
                  _buildDataRow('Construcción + Terreno (Hard Costs):', AppFormatters.currency(hardCosts), isBold: true, isDark: isDark),
                  _buildDataRow(
                    'Gastos Financieros registrados:',
                    p.financieros != null && p.financieros! > 0 ? AppFormatters.currency(p.financieros) : 'Sin registro (\$0.00)',
                    note: p.financieros != null && p.financieros! > 0 ? 'Intereses preoperativos registrados' : null,
                    isDark: isDark,
                  ),
                  _buildDataRow(
                    'Inversión Total del Proyecto:',
                    AppFormatters.currency(totalInvested),
                    isBold: true,
                    highlight: true,
                    valColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                    isDark: isDark,
                  ),

                  // 2. DESGLOSE DE ÁREAS Y SUPERFICIES
                  _buildSectionTitle('DESGLOSE DE SUPERFICIES Y ÁREAS', Icons.straighten_rounded, isDark),
                  _buildDataRow(
                    'Área de bodega registrada:',
                    bodegaArea != null ? '${AppFormatters.number(bodegaArea)} m²' : 'Pendiente',
                    isBold: true,
                    note: 'Superficie cubierta / nave techada',
                    isDark: isDark,
                  ),
                  if (patioArea != null && patioArea > 0) ...[
                    _buildDataRow(
                      'Área de patio segregada:',
                      '${AppFormatters.number(patioArea)} m²',
                      note: '${p.patioRatio?.toStringAsFixed(2) ?? "—"} m² de patio por m² de bodega (segregado)',
                      valColor: const Color(0xFFC2410C),
                      isDark: isDark,
                    ),
                  ],
                  _buildDataRow(
                    'Área Total de Terreno / Predio:',
                    '${AppFormatters.number(totalArea)} m²',
                    isBold: true,
                    note: patioArea != null && patioArea > 0 ? 'Bodega + Patios' : 'Superficie total',
                    isDark: isDark,
                  ),

                  // 3. DATOS GENERALES Y COSTO M2
                  _buildSectionTitle('MÉTRICA UNITARIA Y DATOS DEL PROYECTO', Icons.info_outline_rounded, isDark),
                  _buildDataRow(
                    'Costo por m² asignado:',
                    mainCost != null ? '${AppFormatters.currency(mainCost)} / m²' : 'Pendiente',
                    isBold: true,
                    highlight: true,
                    valColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                    isDark: isDark,
                  ),
                  _buildDataRow('Período de construcción:', p.periodo.isNotEmpty ? p.periodo : '—', isDark: isDark),
                  if (p.ciudad.isNotEmpty)
                    _buildDataRow('Ubicación / Ciudad:', p.ciudad, isDark: isDark),
                  if (p.inquilino.isNotEmpty)
                    _buildDataRow('Inquilino principal:', p.inquilino, isDark: isDark),

                  // 4. OBSERVACIONES DE OBRA / MÉTODO DE CÁLCULO
                  _buildSectionTitle('OBSERVACIONES DE OBRA / MÉTODO DE CÁLCULO', Icons.description_outlined, isDark),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      p.nota.isNotEmpty ? p.nota : 'Sin notas u observaciones registradas para este proyecto.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontStyle: p.nota.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        color: p.nota.isNotEmpty
                            ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))
                            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ),

                  // 5. SIMULADOR INTERACTIVO DE SUPERFICIE
                  _buildSectionTitle('SIMULADOR DE SUPERFICIE (COMPARACIÓN)', Icons.tune_rounded, isDark),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F2E2B) : const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingrese una superficie en m² de bodega para proyectar el costo unitario:',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            labelText: 'Superficie de prueba (m² bodega)',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            suffixText: 'm²',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'COSTO PROYECTADO POR M²',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                simPrincipal != null ? '${AppFormatters.currency(simPrincipal)} / m²' : '—',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Construcción pura / m²:',
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            Text(
                              simConstruccion != null ? '${AppFormatters.currency(simConstruccion)} / m²' : '—',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Construcción + Terreno / m²:',
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            Text(
                              simHard != null ? '${AppFormatters.currency(simHard)} / m²' : '—',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                          ],
                        ),
                        if (p.financieros != null && p.financieros! > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total con Financieros / m²:',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              Text(
                                simTotal != null ? '${AppFormatters.currency(simTotal)} / m²' : '—',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (bodegaArea != null && (_currentArea - bodegaArea).abs() > 1.0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Simulando sobre ${AppFormatters.number(_currentArea)} m² (Área real del proyecto: ${AppFormatters.number(bodegaArea)} m²)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
