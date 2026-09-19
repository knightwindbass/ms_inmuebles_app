import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../logic/dashboard_provider.dart';
import '../../widgets/duo_bar_chart.dart';
import '../../widgets/portfolio_hero_banner.dart';
import '../../widgets/smart_kpi_card.dart';

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

  String _getFormattedDate() {
    final now = DateTime.now();
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final diaSemana = dias[now.weekday - 1];
    final mes = meses[now.month - 1];
    return '$diaSemana, ${now.day} de $mes de ${now.year}';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. ENCABEZADO EJECUTIVO (Logo Eslive, Slogan, Fecha, Notificación, Avatar)
        _buildHeader(kpis, isDark, logoUrl: provider.logoUrl, slogan: provider.slogan),

        const SizedBox(height: 14),

        // 2. BANNER HERO: "Portafolio en movimiento" (Personalizado dinámicamente)
        PortfolioHeroBanner(
          networkImageUrl: provider.bannerUrl ?? kpis.bannerUrl,
        ),

        const SizedBox(height: 18),

        // Filtro por Matriz si está activo
        if (provider.selectedPadreId != null) ...[
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.filter_alt_rounded, size: 14),
                label: Text('Filtrado por Matriz #${provider.selectedPadreId}', style: const TextStyle(fontSize: 12)),
                onPressed: () => provider.filterByMatriz(null),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 3. TARJETAS INTELIGENTES (6 SMART KPI CARDS)
        _buildSmartKpiCards(kpis, isDark),

        const SizedBox(height: 18),

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

  Widget _buildHeader(dynamic kpis, bool isDark, {String? logoUrl, String? slogan}) {
    final effectiveLogoUrl = (logoUrl != null && logoUrl.isNotEmpty) ? logoUrl : kpis.logoUrl;
    final effectiveSlogan = (slogan != null && slogan.isNotEmpty) ? slogan : kpis.displaySlogan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Horizontal Eslive (o Logo del Tenant) + Slogan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (effectiveLogoUrl != null && effectiveLogoUrl.isNotEmpty)
                    Image.network(
                      effectiveLogoUrl,
                      height: 28,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => Image.asset(
                        isDark
                            ? 'assets/images/eslive_logo_horizontal_white.png'
                            : 'assets/images/eslive_logo_horizontal.png',
                        height: 28,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    )
                  else
                    Image.asset(
                      isDark
                          ? 'assets/images/eslive_logo_horizontal_white.png'
                          : 'assets/images/eslive_logo_horizontal.png',
                      height: 28,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => Text(
                        'Eslive',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    effectiveSlogan,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Fecha Actual Dinámica y Real (para capturas de pantalla)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 5),
              Text(
                _getFormattedDate(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartKpiCards(dynamic kpis, bool isDark) {
    return Column(
      children: [
        // Fila 1: Renta mensual (base) & Ocupación (m²)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SmartKpiCard(
                  title: 'Renta mensual (base)',
                  value: AppFormatters.currencyNoDecimals(kpis.displayRentaMensual),
                  trendBadge: kpis.displayTendenciaRentaMensual,
                  trendContext: 'vs. mes anterior',
                  icon: Icons.attach_money_rounded,
                  iconBgColor: const Color(0xFF10B981),
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SmartKpiCard(
                  title: 'Ocupación (m²)',
                  value: '${kpis.displayTasaOcupacion.toStringAsFixed(1)}%',
                  subtitle: '${AppFormatters.number(kpis.displayAreaOcupada.toInt())} m² ocupados de ${AppFormatters.number(kpis.displayAreaTotal.toInt())} m²',
                  isSubtitleHighlighted: true,
                  icon: Icons.trending_up_rounded,
                  iconBgColor: const Color(0xFF2563EB),
                  iconColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Fila 2: Renta prom. portafolio & Área total rentable
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SmartKpiCard(
                  title: 'Renta prom. portafolio',
                  value: '\$${kpis.displayRentaPromedioM2.toStringAsFixed(2)}',
                  valueSuffix: '/ m² / mes',
                  trendBadge: kpis.displayTendenciaRentaPromedio,
                  trendContext: 'vs. año anterior',
                  icon: Icons.monetization_on_rounded,
                  iconBgColor: const Color(0xFF8B5CF6),
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SmartKpiCard(
                  title: 'Área total rentable',
                  value: '${AppFormatters.number(kpis.displayAreaTotal.toInt())} m²',
                  subtitle: 'Portafolio consolidado',
                  icon: Icons.crop_free_rounded,
                  iconBgColor: Colors.transparent,
                  iconColor: const Color(0xFF475569),
                  isOutlinedIcon: true,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Fila 3: Área vacante & Renta potencial (100%)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SmartKpiCard(
                  title: 'Área vacante',
                  value: '${AppFormatters.number(kpis.displayAreaVacante.toInt())} m²',
                  subtitle: '${((kpis.displayAreaVacante / (kpis.displayAreaTotal > 0 ? kpis.displayAreaTotal : 1)) * 100).toStringAsFixed(1)}% del total',
                  icon: Icons.inventory_2_outlined,
                  iconBgColor: const Color(0xFF475569),
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SmartKpiCard(
                  title: 'Renta potencial (100%)',
                  value: AppFormatters.currencyNoDecimals(kpis.displayRentaPotencial),
                  valueSuffix: '/ mes',
                  trendBadge: kpis.displayTendenciaRentaPotencial,
                  trendContext: 'vs. actual',
                  icon: Icons.bar_chart_rounded,
                  iconBgColor: const Color(0xFF334155),
                  iconColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
