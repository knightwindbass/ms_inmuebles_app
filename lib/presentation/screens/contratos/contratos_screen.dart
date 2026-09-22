import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/contrato_model.dart';
import '../../../logic/contratos_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/kpi_metric_card.dart';
import 'contrato_detail_screen.dart';

/// Pantalla de Dashboard y Registro Maestro de Contratos (/contratos).
class ContratosScreen extends StatefulWidget {
  const ContratosScreen({super.key});

  @override
  State<ContratosScreen> createState() => _ContratosScreenState();
}

class _ContratosScreenState extends State<ContratosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContratosProvider>(context, listen: false).fetchContratos();
    });
  }

  void _showSortModal(ContratosProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Criterio de Ordenación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: const Text('Próximos a vencer (vencimiento_asc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenVencimientoAsc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenVencimientoAsc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Mayor tiempo restante (vencimiento_desc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenVencimientoDesc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenVencimientoDesc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_rounded),
                title: const Text('Mayor monto (monto_desc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenMontoDesc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenMontoDesc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Menor monto (monto_asc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenMontoAsc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenMontoAsc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Inquilino A-Z (inquilino_asc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenInquilinoAsc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenInquilinoAsc);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper de Indicador Visual de Tiempo Restante (Guía Técnica)
  Widget _buildStatusBadge(String fechaFinStr) {
    if (fechaFinStr.isEmpty) return const SizedBox.shrink();
    try {
      final DateTime hoy = DateTime.now();
      final DateTime fechaFin = DateTime.parse(fechaFinStr);
      final int diasRestantes = fechaFin.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;

      Color badgeColor;
      String badgeText;

      if (diasRestantes <= 0) {
        // Vencido (Rojo/Naranja Fuerte)
        badgeColor = const Color(0xFFEF4444);
        badgeText = 'Vencido (${diasRestantes.abs()}d)';
      } else if (diasRestantes <= 60) {
        // Alerta Naranja (Próximo a vencer en <= 60 días)
        badgeColor = const Color(0xFFF59E0B);
        badgeText = '$diasRestantes días';
      } else {
        // Vigente y Saludable (Verde)
        badgeColor = const Color(0xFF10B981);
        badgeText = '$diasRestantes días';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          badgeText,
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<ContratosProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Barra de Búsqueda & Ordenación
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    hintText: 'Buscar por inquilino, inmueble o # contrato...',
                    initialValue: provider.searchQuery,
                    onSearch: (q) => provider.setSearchQuery(q),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF2563EB)),
                  tooltip: 'Criterio de Ordenación',
                  onPressed: () => _showSortModal(provider),
                ),
              ],
            ),
          ),

          // Lista con Pull-to-Refresh y KPIs en cabecera
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchContratos(),
              child: _buildBody(provider, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ContratosProvider provider, bool isDark) {
    if (provider.isLoading && provider.contratos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.contratos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Error al cargar contratos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchContratos(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // -------------------------------------------------------------
        // Tarjetas KPI Superiores (Calculadas en Frontend)
        // -------------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: KpiMetricCard(
                title: 'MRR Contratos',
                value: AppFormatters.currency(provider.mrr),
                subtitle: 'Ingreso recurrente activo',
                icon: Icons.payments_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiMetricCard(
                title: 'Vigentes',
                value: '${provider.totalActivos}',
                subtitle: '${provider.contratos.length} contratos total',
                icon: Icons.verified_user_rounded,
                accentColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Tarjeta Alerta de Renovación (Vencen en <= 60 días)
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notification_important_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alerta de Renovación (≤ 60 días)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.porVencer > 0
                            ? '${provider.porVencer} contrato(s) requieren atención próxima'
                            : 'Todos los contratos tienen más de 60 días de vigencia',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.porVencer > 0
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.porVencer}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: provider.porVencer > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Título de sección de listado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Registro de Contratos',
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${provider.contratos.length} contratos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (provider.contratos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 48, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  const SizedBox(height: 10),
                  const Text('No se encontraron contratos con los filtros aplicados'),
                ],
              ),
            ),
          )
        else
          ...provider.contratos.map((c) => _buildContratoCard(c, isDark)),
      ],
    );
  }

  Widget _buildContratoCard(ContratoModel contrato, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContratoDetailScreen(contratoId: contrato.id, initialContrato: contrato),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Inquilino y Badge de Vencimiento
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contrato.nombresInquilino,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contrato.numeroContrato != null && contrato.numeroContrato!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Contrato: ${contrato.numeroContrato}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(contrato.fechaFin),
                ],
              ),
              const SizedBox(height: 10),

              // Inmueble y Propietario (Soporte Multipropropiedad Agrupada)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      contrato.tieneMultiplesInmuebles ? Icons.domain_rounded : Icons.apartment_rounded,
                      size: 16,
                      color: contrato.tieneMultiplesInmuebles ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    if (contrato.tieneMultiplesInmuebles) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${contrato.cantidadInmuebles} inmuebles',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        '${contrato.resumenInmuebles}${contrato.totalMetraje > 0 ? ' • ${AppFormatters.area(contrato.totalMetraje)}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (contrato.propietario != null && contrato.propietario!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${contrato.propietario})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 20),

              // Pie de Tarjeta: Canon de Renta y Fechas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'Vence: ${AppFormatters.date(contrato.fechaFin)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormatters.currency(contrato.valorPactado),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            contrato.frecuenciaPago.toLowerCase() == 'anual' ? '/año' : '/mes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      if (contrato.tieneMultiplesInmuebles)
                        const Text(
                          'Total Acumulado',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
