import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../logic/dashboard_provider.dart';
import '../../widgets/duo_bar_chart.dart';
import '../../widgets/kpi_metric_card.dart';

/// Pantalla Principal del Dashboard de Inteligencia de Negocios y Reportes (/dashboard/resumen).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: _buildBody(provider, isDark),
      ),
    );
  }

  Widget _buildBody(DashboardProvider provider, bool isDark) {
    if (provider.isLoading && provider.kpis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.kpis == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 54, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error al cargar métricas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final kpis = provider.kpis;
    if (kpis == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      children: [
        // Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel de Control',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Métricas en tiempo real del portafolio',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (provider.selectedPadreId != null)
              ActionChip(
                avatar: const Icon(Icons.filter_alt_rounded, size: 14),
                label: Text('Matriz #${provider.selectedPadreId}', style: const TextStyle(fontSize: 11)),
                onPressed: () => provider.filterByMatriz(null),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Fila 1 de Tarjetas KPI: MRR & Tasa de Ocupación
        Row(
          children: [
            Expanded(
              child: KpiMetricCard(
                title: 'MRR Proyectado',
                value: AppFormatters.currency(kpis.ingresosMensualesProyectados),
                subtitle: 'Ingreso recurrente',
                icon: Icons.payments_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiMetricCard(
                title: 'Tasa Ocupación',
                value: AppFormatters.percentage(kpis.tasaOcupacion),
                subtitle: '${kpis.inmuebles.rentados}/${kpis.inmuebles.total} ocupados',
                icon: Icons.pie_chart_rounded,
                accentColor: const Color(0xFF2563EB),
                trailing: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: (kpis.tasaOcupacion > 1 ? kpis.tasaOcupacion / 100 : kpis.tasaOcupacion).clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Fila 2 de Tarjetas KPI: Total Inmuebles & Composición del Parque
        Row(
          children: [
            Expanded(
              child: KpiMetricCard(
                title: 'Total Inmuebles',
                value: '${kpis.inmuebles.total}',
                subtitle: '${kpis.inmuebles.disponibles} libres | ${kpis.inmuebles.rentados} rentados',
                icon: Icons.apartment_rounded,
                accentColor: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiMetricCard(
                title: 'Composición',
                value: '${kpis.jerarquia.princActivas}P • ${kpis.jerarquia.subActivas}S',
                subtitle: '${kpis.jerarquia.totalPrincipales} princ., ${kpis.jerarquia.totalSubunidades} sub.',
                icon: Icons.account_tree_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tarjeta de Composición Jerárquica del Parque (A prueba de desbordamientos)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Composición del Parque',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${kpis.inmuebles.total} Unidades',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Columna Principales / Matrices
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
                                const Icon(Icons.domain_rounded, size: 15, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Principales',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Activas:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                Text('${kpis.jerarquia.princActivas}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Inactivas:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                Text('${kpis.jerarquia.princInactivas}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Columna Sub-unidades
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
                                const Icon(Icons.meeting_room_rounded, size: 15, color: Color(0xFF8B5CF6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Sub-unidades',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Activas:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                Text('${kpis.jerarquia.subActivas}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Inactivas:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                Text('${kpis.jerarquia.subInactivas}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfico Dúo: Distribución Tipos vs Estado (Edificio, Bodega, Local, Oficina, Terreno)
        DuoBarChartWidget(data: kpis.distribucionTiposEstado),
        const SizedBox(height: 24),
      ],
    );
  }
}
