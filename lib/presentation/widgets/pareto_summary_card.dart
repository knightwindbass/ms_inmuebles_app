import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/pareto_model.dart';
import '../screens/dashboard/pareto_top_ten_screen.dart';

/// Tarjeta ejecutiva de resumen del Análisis de Pareto (80/20) para el Dashboard.
/// Muestra la concentración del Top 10 y al pulsarse navega al ranking detallado.
class ParetoSummaryCard extends StatelessWidget {
  final ParetoResumenModel? pareto;
  final double totalMrrFallback;

  const ParetoSummaryCard({
    super.key,
    required this.pareto,
    this.totalMrrFallback = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double totalMrr = (pareto != null && pareto!.totalMrr > 0)
        ? pareto!.totalMrr
        : totalMrrFallback;
    final double mrrTopTen = pareto?.mrrTopTen ?? 0.0;
    final double pctTopTen = (pareto != null && pareto!.participacionTopTenPct > 0)
        ? pareto!.participacionTopTenPct
        : (totalMrr > 0 ? (mrrTopTen / totalMrr) * 100 : 0.0);
    final double pctResto = (100.0 - pctTopTen).clamp(0.0, 100.0);
    final double mrrResto = (totalMrr - mrrTopTen).clamp(0.0, double.infinity);
    final int vitalCount = pareto?.vitalCount ?? 0;
    final int totalEmpresas = pareto?.totalEmpresas ?? 0;
    final topItems = pareto?.topTen ?? [];

    return Container(
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ParetoTopTenScreen(initialPareto: pareto),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Encabezado de la Tarjeta
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Color(0xFFEAB308),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Top 10 Pareto de Renta',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '80/20',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Concentración por Razón Social Legal',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Ver Top 10',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Métrica Principal: Participación y Canon Total Top 10
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${pctTopTen.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'del ingreso mensual aportado por el Top 10',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${AppFormatters.currency(mrrTopTen)} / mes sobre un total de ${AppFormatters.currency(totalMrr)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Barra de Concentración Bicolor
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 12,
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

                // Leyenda de la Barra
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🟢 Top 10: ${AppFormatters.currencyNoDecimals(mrrTopTen)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '⚪ Resto: ${AppFormatters.currencyNoDecimals(mrrResto)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),

                // 4. Mini vista de las primeras empresas del ranking (si están disponibles)
                if (topItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  ...topItems.take(2).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            item.medal,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.empresa,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.participacionPct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.currencyNoDecimals(item.mrr),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 6),

                // 5. Pill de Contexto Vital (80%)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 15,
                        color: Color(0xFFEAB308),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vitalCount > 0
                              ? '$vitalCount de $totalEmpresas empresas conforman la Zona Vital (80% del ingreso)'
                              : 'Toca para auditar el ranking completo y concentración 80/20',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
