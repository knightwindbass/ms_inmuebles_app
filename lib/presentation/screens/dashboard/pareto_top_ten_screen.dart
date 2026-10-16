import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/pareto_model.dart';
import '../../../logic/dashboard_provider.dart';

/// Pantalla Ejecutiva del Análisis de Pareto (80/20) y Ranking Top 10 de Renta Mensual.
class ParetoTopTenScreen extends StatefulWidget {
  final ParetoResumenModel? initialPareto;

  const ParetoTopTenScreen({super.key, this.initialPareto});

  @override
  State<ParetoTopTenScreen> createState() => _ParetoTopTenScreenState();
}

class _ParetoTopTenScreenState extends State<ParetoTopTenScreen> {
  int _selectedFilterIndex = 0; // 0 = Top 10, 1 = Todos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchParetoReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DashboardProvider>(context);

    final pareto = provider.paretoFullReport ??
        provider.paretoTopTen ??
        widget.initialPareto;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 10 Pareto de Renta',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Concentración por Razón Social Legal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          if (provider.isLoadingPareto)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Actualizar reporte',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                provider.fetchParetoReport(forceRefresh: true);
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchParetoReport(forceRefresh: true);
        },
        child: pareto == null && provider.isLoadingPareto
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(context, pareto, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ParetoResumenModel? pareto, bool isDark) {
    if (pareto == null || pareto.topTen.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No hay datos suficientes de contratos vigentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'El ranking de Pareto se calcula automáticamente a partir de los cánones mensuales de contratos vigentes.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final double totalMrr = pareto.totalMrr;
    final double mrrTopTen = pareto.mrrTopTen;
    final double pctTopTen = pareto.participacionTopTenPct;
    final double pctResto = pareto.participacionRestoPct;
    final double mrrResto = pareto.mrrResto;
    final int vitalCount = pareto.vitalCount;
    final int totalEmpresas = pareto.totalEmpresas;

    final displayList = (_selectedFilterIndex == 0 || pareto.rankingCompleto.isEmpty)
        ? pareto.topTen
        : pareto.rankingCompleto;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. Grid de 4 KPIs Ejecutivos
        _buildKpisGrid(totalMrr, mrrTopTen, pctTopTen, vitalCount, totalEmpresas, isDark),

        const SizedBox(height: 14),

        // 2. Barra Visual de Concentración de Cartera (80/20)
        _buildConcentracionCard(totalMrr, mrrTopTen, pctTopTen, pctResto, mrrResto, isDark),

        const SizedBox(height: 16),

        // 3. Selector de Pestañas / Filtro (Top 10 vs Todos)
        if (pareto.rankingCompleto.length > pareto.topTen.length) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    title: 'Top 10 Empresas (${pareto.topTen.length})',
                    isSelected: _selectedFilterIndex == 0,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedFilterIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildFilterTab(
                    title: 'Todos los Inquilinos (${pareto.rankingCompleto.length})',
                    isSelected: _selectedFilterIndex == 1,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedFilterIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 4. Encabezado de la Lista
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedFilterIndex == 0 ? 'Ranking Top 10 Clientes' : 'Ranking Completo de Cartera',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${displayList.length} ${displayList.length == 1 ? "empresa" : "empresas"}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 5. Tarjetas del Ranking de Empresas
        ...displayList.map((item) {
          return _buildParetoItemCard(context, item, isDark);
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterTab({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildKpisGrid(
    double totalMrr,
    double mrrTopTen,
    double pctTopTen,
    int vitalCount,
    int totalEmpresas,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniKpiCard(
                title: 'MRR Portafolio',
                value: AppFormatters.currencyNoDecimals(totalMrr),
                subtitle: '100% contratos',
                accentColor: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniKpiCard(
                title: 'Aporte Top 10',
                value: AppFormatters.currencyNoDecimals(mrrTopTen),
                subtitle: '${pctTopTen.toStringAsFixed(1)}% de la cartera',
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMiniKpiCard(
                title: 'Zona Vital (80%)',
                value: '$vitalCount empresas',
                subtitle: 'Generan el 80% de renta',
                accentColor: const Color(0xFFEAB308),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniKpiCard(
                title: 'Total Cartera',
                value: '$totalEmpresas razones',
                subtitle: 'Personerías jurídicas',
                accentColor: const Color(0xFF64748B),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
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
          const SizedBox(height: 6),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConcentracionCard(
    double totalMrr,
    double mrrTopTen,
    double pctTopTen,
    double pctResto,
    double mrrResto,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONCENTRACIÓN DE RENTA (80/20)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
              Text(
                'Top 10: ${pctTopTen.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 14,
              width: double.infinity,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              child: Row(
                children: [
                  if (pctTopTen > 0)
                    Expanded(
                      flex: (pctTopTen * 10).toInt().clamp(1, 1000),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF10B981)],
                          ),
                        ),
                      ),
                    ),
                  if (pctResto > 0)
                    Expanded(
                      flex: (pctResto * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🟢 Top 10 Clave: ${AppFormatters.currencyNoDecimals(mrrTopTen)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              Text(
                '⚪ Resto Cartera: ${AppFormatters.currencyNoDecimals(mrrResto)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParetoItemCard(BuildContext context, ParetoItemModel item, bool isDark) {
    final isTopThree = item.posicion <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTopThree
              ? (item.posicion == 1
                  ? const Color(0xFFEAB308).withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isTopThree && item.posicion == 1 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showItemDetailSheet(context, item, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila 1: Posición + Razón Social + Canon Mensual
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medalla / Posición
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTopThree
                            ? const Color(0xFFEAB308).withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.medal,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isTopThree
                              ? const Color(0xFFD97706)
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Razón Social
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.empresa,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (item.hasDetailedSucursales) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Sucursales: ${item.sucursales}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Monto Mensual
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.currency(item.mrr),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '/ mes',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Fila 2: Chips informativos (RUC, Locales, % Participación, % Acumulado, Zona Vital)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // RUC
                    if (item.ruc.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          item.ruc,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          ),
                        ),
                      ),

                    // Locales
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.totalLocales} ${item.totalLocales == 1 ? "local" : "locales"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),

                    // Participación %
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.participacionPct.toStringAsFixed(1)}% cartera',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),

                    // Acumulado %
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Acum: ${item.acumuladoPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),

                    // Zona Vital 80% Badge
                    if (item.esVital80)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 3),
                            Text(
                              'Zona 80%',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showItemDetailSheet(BuildContext context, ParetoItemModel item, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.medal,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.empresa,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (item.ruc.isNotEmpty)
                            Text(
                              'RUC: ${item.ruc}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                _buildSheetRow('Canon Mensual Portafolio:', AppFormatters.currency(item.mrr), isDark, highlight: true),
                const SizedBox(height: 8),
                _buildSheetRow('Participación en Cartera:', '${item.participacionPct.toStringAsFixed(2)}%', isDark),
                const SizedBox(height: 8),
                _buildSheetRow('Porcentaje Acumulado:', '${item.acumuladoPct.toStringAsFixed(2)}%', isDark),
                const SizedBox(height: 8),
                _buildSheetRow('Unidades / Locales Rentados:', '${item.totalLocales} unidades', isDark),
                if (item.hasDetailedSucursales) ...[
                  const SizedBox(height: 8),
                  _buildSheetRow('Sucursales / Locales:', item.sucursales, isDark),
                ],
                const SizedBox(height: 8),
                _buildSheetRow(
                  'Zona de Pareto:',
                  item.esVital80 ? 'Zona Vital 80% (Estratégico)' : 'Zona Complementaria (20%)',
                  isDark,
                  textColor: item.esVital80 ? const Color(0xFF10B981) : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(String label, String value, bool isDark, {bool highlight = false, Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: highlight ? 14 : 12.5,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }
}
