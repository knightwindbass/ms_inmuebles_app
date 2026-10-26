import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/deuda_inmobiliaria_model.dart';
import '../../../logic/deuda_provider.dart';
import 'proyecto_deuda_detail_screen.dart';

/// Pantalla Principal del Dashboard Ejecutivo de Deuda y Riesgos Inmobiliarios
/// Implementada según la interfaz y métricas del prototipo GenUI / ChatGPT.
class DeudaDashboardScreen extends StatefulWidget {
  const DeudaDashboardScreen({super.key});

  @override
  State<DeudaDashboardScreen> createState() => _DeudaDashboardScreenState();
}

class _DeudaDashboardScreenState extends State<DeudaDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeudaProvider>(context, listen: false).fetchDeudaDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DeudaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pasivos & Riesgos',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar datos',
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: _buildBody(provider, isDark),
      ),
    );
  }

  Widget _buildBody(DeudaProvider provider, bool isDark) {
    if (provider.isLoading && provider.deudaDashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.deudaDashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error al cargar cartera de deuda',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
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

    final data = provider.deudaDashboard;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final resumen = data.resumen;
    final proyectos = data.proyectos;
    final bancos = data.distribucionBancos;

    const colorTeal = Color(0xFF0D9488);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Subtítulo oficial
        Text(
          'ESLIVE | Dashboard de Deuda Inmobiliaria',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colorTeal,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Corte financiero: ${data.corteFecha}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),

        // TARJETA PRINCIPAL CONSOLIDADA
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEUDA TOTAL CONSOLIDADA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppFormatters.currency(resumen.deudaTotalConsolidada),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: colorTeal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reducción neta: ≈ \$${(resumen.reduccionNetaCapital / 1000000).toStringAsFixed(2)} M (${resumen.porcentajeReduccionTotal.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 CHIPS MÉTRICOS (2x2 GRID)
              Row(
                children: [
                  Expanded(
                    child: _buildKpiChip(
                      title: 'Pago mensual',
                      value: AppFormatters.currency(resumen.pagoMensualRegistrado),
                      subtitle: 'Capital + Intereses',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiChip(
                      title: 'Pago anualizado',
                      value: '\$${(resumen.pagoAnualizado / 1000000).toStringAsFixed(2)} M',
                      subtitle: 'Compromiso 12m',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiChip(
                      title: 'Monto original',
                      value: '\$${(resumen.montoOriginalRegistrado / 1000000).toStringAsFixed(2)} M',
                      subtitle: '9 Proyectos activos',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiChip(
                      title: 'Reducción neta',
                      value: '≈ \$${(resumen.reduccionNetaCapital / 1000000).toStringAsFixed(2)} M',
                      subtitle: '${resumen.porcentajeReduccionTotal.toStringAsFixed(1)}% amortizado',
                      isDark: isDark,
                      highlightColor: colorTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // BANNER DE FLUJO NETO OPERATIVO INMOBILIARIO
        if (resumen.rentasMensualesVigentes > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : (resumen.flujoNetoMensual >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: resumen.flujoNetoMensual >= 0 ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  resumen.flujoNetoMensual >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: resumen.flujoNetoMensual >= 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cruce Operativo (Rentas vs Deuda Op)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (resumen.coberturaDscr != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: resumen.coberturaDscr! >= 1.25
                                    ? const Color(0xFFDCFCE7)
                                    : (resumen.coberturaDscr! >= 1.0 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DSCR ${resumen.coberturaDscr!.toStringAsFixed(2)}x',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: resumen.coberturaDscr! >= 1.25
                                      ? const Color(0xFF166534)
                                      : (resumen.coberturaDscr! >= 1.0 ? const Color(0xFF92400E) : const Color(0xFF991B1B)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rentas: ${AppFormatters.currency(resumen.rentasMensualesVigentes)}/m  •  Deuda Op: ${AppFormatters.currency(resumen.pagoMensualOperativo)}/m (${resumen.proyectosOperativosCount} de ${proyectos.length} consid.)',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${resumen.flujoNetoMensual >= 0 ? '+' : ''}${AppFormatters.currency(resumen.flujoNetoMensual)}/m',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: resumen.flujoNetoMensual >= 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // DISTRIBUCIÓN BANCARIA PILLS
        if (bancos.isNotEmpty) ...[
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bancos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final b = bancos[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${b.banco}: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '\$${(b.saldo / 1000000).toStringAsFixed(2)} M (${b.porcentaje}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],

        // TÍTULO DE LISTA DE PROYECTOS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detalle por proyecto (${proyectos.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Base corte Septiembre',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // TARJETAS DE PROYECTOS
        ...proyectos.map((p) => _buildProjectCard(context, p, isDark, colorTeal)),

        const SizedBox(height: 16),

        // NOTA METODOLÓGICA
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            'Base oficial: Cuadro de Riesgos Inmobiliarios ESLIVE, corte al 30 de septiembre de 2026. Los porcentajes reflejan reducción neta de capital. Obligaciones sujetas a consolidación bancaria en noviembre de 2026.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildKpiChip({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: highlightColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    ProyectoDeudaModel p,
    bool isDark,
    Color colorTeal,
  ) {
    final pct = p.porcentajeReducido;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.esDeudaOperativa
                                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: p.esDeudaOperativa
                                  ? const Color(0xFFA7F3D0)
                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Text(
                            p.esDeudaOperativa ? '✓ Op' : '— No Op',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: p.esDeudaOperativa
                                  ? const Color(0xFF047857)
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.monthly != null
                          ? 'Pago mensual: ${AppFormatters.currency(p.monthly!)}'
                          : 'Pago mensual: Por confirmar',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currency(p.balance),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pct.toStringAsFixed(1)}% amortizado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // BARRA DE PROGRESO TEAL
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(color: colorTeal),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Vencimiento: ${p.end}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProyectoDeudaDetailScreen(proyecto: p),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver detalle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
