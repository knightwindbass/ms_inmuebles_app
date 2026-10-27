import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../logic/inversiones_provider.dart';
import '../screens/dashboard/inversiones_historicas_screen.dart';

/// Tarjeta Resumen Ejecutiva de Inversión Histórica en Proyectos para el Dashboard Principal.
class InversionSummaryCard extends StatefulWidget {
  const InversionSummaryCard({super.key});

  @override
  State<InversionSummaryCard> createState() => _InversionSummaryCardState();
}

class _InversionSummaryCardState extends State<InversionSummaryCard> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<InversionesProvider>(context);

    final data = provider.data;
    const colorTeal = Color(0xFF0D9488);
    const colorBlue = Color(0xFF2563EB);
    const colorAmber = Color(0xFFD97706);

    if (provider.isLoading && data == null) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    final resumen = data.resumen;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InversionesHistoricasScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Encabezado de la Tarjeta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: colorTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inversión Histórica en Proyectos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Corte: ${data.corteFecha} • ${resumen.totalProyectos} Proyectos',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Cifras Principales: Inversión Total vs Construcción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVERSIÓN TOTAL CONSOLIDADA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.compactCurrency(resumen.inversionTotal),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          AppFormatters.currency(resumen.inversionTotal),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CONSTRUCCIÓN (OBRAS)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.compactCurrency(resumen.construccionTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorTeal,
                          ),
                        ),
                        Text(
                          '${resumen.pctConstruccion.toStringAsFixed(1)}% del total',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Barra de Distribución Proporcional Segmentada
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    child: Row(
                      children: [
                        Flexible(
                          flex: (resumen.pctConstruccion * 10).toInt(),
                          child: Container(color: colorTeal),
                        ),
                        Flexible(
                          flex: (resumen.pctTerreno * 10).toInt(),
                          child: Container(color: colorBlue),
                        ),
                        Flexible(
                          flex: (resumen.pctFinancieros * 10).toInt(),
                          child: Container(color: colorAmber),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. Desglose en Micro-Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem(
                      color: colorTeal,
                      label: 'Obras: ${AppFormatters.compactCurrency(resumen.construccionTotal)}',
                      isDark: isDark,
                    ),
                    _buildLegendItem(
                      color: colorBlue,
                      label: 'Terrenos: ${AppFormatters.compactCurrency(resumen.terrenosTotal)}',
                      isDark: isDark,
                    ),
                    _buildLegendItem(
                      color: colorAmber,
                      label: 'Financieros: ${AppFormatters.compactCurrency(resumen.financierosTotal)}',
                      isDark: isDark,
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
