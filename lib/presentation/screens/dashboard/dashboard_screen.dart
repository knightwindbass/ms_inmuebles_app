import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../logic/dashboard_provider.dart';
import '../../widgets/analytics_slide_block.dart';
import '../../widgets/portfolio_hero_banner.dart';
import '../../widgets/smart_kpi_card.dart';
import 'categoria_kpi_screen.dart';
import 'terrenos_dashboard_screen.dart';

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

        // Sección Interactiva Deslizable: Composición del Parque & Acceso a KPIs por Categoría
        _buildComposicionParque(context, provider, kpis, isDark),
        const SizedBox(height: 16),

        // Bloque Deslizable (Slide): Tipología & Rentabilidad por Ubicación
        AnalyticsSlideBlock(
          distribucion: kpis.distribucionTiposEstado,
          rentabilidad: kpis.rentabilidadUbicacion,
        ),
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
    final double areaTotal = kpis.displayAreaTotal;
    final double areaVacante = kpis.displayAreaVacante;
    final double pctVacante = areaTotal > 0 ? (areaVacante / areaTotal) * 100 : 0.0;
    final double upside = (kpis.displayRentaPotencial - kpis.displayRentaMensual);
    final String upsideSubtitle = upside > 0
        ? '+${AppFormatters.currencyNoDecimals(upside)} al 100% de ocupación'
        : 'Portafolio al 100% de ocupación';

    return Column(
      children: [
        // Tarjeta Inteligente: Renta Anual Proyectada (Abarca el ancho completo de las 2 columnas)
        _buildRentaAnualCard(kpis, isDark),

        const SizedBox(height: 10),

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
                  trendContext: kpis.displayTendenciaRentaMensual != null ? 'vs. mes anterior' : null,
                  subtitle: kpis.displayTendenciaRentaMensual == null ? 'Facturación mensual contractual' : null,
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
                  subtitle: '${AppFormatters.number(kpis.displayAreaOcupada.toInt())} m² rentados de ${AppFormatters.number(areaTotal.toInt())} m²',
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
                  trendContext: kpis.displayTendenciaRentaPromedio != null ? 'vs. período anterior' : null,
                  subtitle: kpis.displayTendenciaRentaPromedio == null ? 'Por m² rentado' : null,
                  icon: Icons.monetization_on_rounded,
                  iconBgColor: const Color(0xFF8B5CF6),
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SmartKpiCard(
                  title: 'Área total rentable',
                  value: '${AppFormatters.number(areaTotal.toInt())} m²',
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
                  value: '${AppFormatters.number(areaVacante.toInt())} m²',
                  subtitle: '${pctVacante.toStringAsFixed(1)}% del total disponible',
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
                  trendContext: kpis.displayTendenciaRentaPotencial != null ? 'vs. actual' : null,
                  subtitle: kpis.displayTendenciaRentaPotencial == null ? upsideSubtitle : null,
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

  /// Tarjeta de Renta Anual Proyectada de ancho completo (abarca las 2 columnas)
  Widget _buildRentaAnualCard(dynamic kpis, bool isDark) {
    final double rentaAnual = kpis.displayRentaAnual;
    final double rentaMensual = kpis.displayRentaMensual;

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
              Icons.calendar_month_rounded,
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
                      'Renta Anual Proyectada',
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
                        '12 meses',
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      AppFormatters.currencyNoDecimals(rentaAnual),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ año',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Facturación anual contractual (${AppFormatters.currencyNoDecimals(rentaMensual)} / mes)',
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

  /// Sección Interactiva con Scroll Horizontal: Jerarquía + Botones de Categorías con KPIs
  Widget _buildComposicionParque(BuildContext context, DashboardProvider provider, dynamic kpis, bool isDark) {
    int getCategoryCount(String tipo) {
      if (tipo.toLowerCase() == 'terreno') {
        final tCount = provider.terrenosKpis?.inmuebles.total;
        if (tCount != null && tCount > 0) return tCount;
      }
      for (final d in kpis.distribucionTiposEstado) {
        if (d.tipo.toLowerCase() == tipo.toLowerCase()) {
          return d.libres + d.ocupadas;
        }
      }
      return 0;
    }

    final categories = [
      {
        'tipo': 'Edificio',
        'label': 'Edificios',
        'icon': Icons.domain_rounded,
        'color': const Color(0xFF2563EB),
        'count': getCategoryCount('Edificio'),
      },
      {
        'tipo': 'Bodega',
        'label': 'Bodegas',
        'icon': Icons.warehouse_rounded,
        'color': const Color(0xFF0284C7),
        'count': getCategoryCount('Bodega'),
      },
      {
        'tipo': 'Local',
        'label': 'Locales',
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFF10B981),
        'count': getCategoryCount('Local'),
      },
      {
        'tipo': 'Oficina',
        'label': 'Oficinas',
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFFF59E0B),
        'count': getCategoryCount('Oficina'),
      },
      {
        'tipo': 'Terreno',
        'label': 'Terrenos',
        'icon': Icons.landscape_rounded,
        'color': const Color(0xFF8B5CF6),
        'count': getCategoryCount('Terreno'),
        'badge': 'Land Banking',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Composición del Parque',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Desliza horizontalmente para explorar categorías →',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
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
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 1. Tarjeta Principales / Matrices
                  _buildHierarchyCard(
                    title: 'Principales',
                    icon: Icons.domain_rounded,
                    iconColor: const Color(0xFF2563EB),
                    activas: kpis.jerarquia.princActivas,
                    inactivas: kpis.jerarquia.princInactivas,
                    total: kpis.jerarquia.totalPrincipales,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  // 2. Tarjeta Sub-unidades
                  _buildHierarchyCard(
                    title: 'Sub-unidades',
                    icon: Icons.meeting_room_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    activas: kpis.jerarquia.subActivas,
                    inactivas: kpis.jerarquia.subInactivas,
                    total: kpis.jerarquia.totalSubunidades,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  // 3. Botones para cada Categoría
                  ...categories.map((cat) {
                    final tipo = cat['tipo'] as String;
                    final label = cat['label'] as String;
                    final icon = cat['icon'] as IconData;
                    final color = cat['color'] as Color;
                    final count = cat['count'] as int;
                    final badge = cat['badge'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildCategoryButton(
                        tipo: tipo,
                        label: label,
                        icon: icon,
                        color: color,
                        count: count,
                        badge: badge,
                        isDark: isDark,
                        onTap: () {
                          if (tipo.toLowerCase() == 'terreno') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TerrenosDashboardScreen(),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CategoriaKpiScreen(tipo: tipo),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int activas,
    required int inactivas,
    required int total,
    required bool isDark,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activas:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              Text('$activas', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inactivas:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              Text('$inactivas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Total: $total',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required String tipo,
    required String label,
    required IconData icon,
    required Color color,
    required int count,
    String? badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.45 : 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  Row(
                    children: [
                      Text(
                        'KPIs',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 9, color: color),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? "unidad" : "unidades"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (badge != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
