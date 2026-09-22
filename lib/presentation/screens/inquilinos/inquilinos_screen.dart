import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/contrato_model.dart';
import '../../../data/models/inquilino_model.dart';
import '../../../logic/contratos_provider.dart';
import '../../../logic/inquilinos_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/kpi_metric_card.dart';
import '../contratos/contrato_detail_screen.dart';

/// Pantalla del Directorio de Inquilinos y Clientes (/inquilinos).
class InquilinosScreen extends StatefulWidget {
  const InquilinosScreen({super.key});

  @override
  State<InquilinosScreen> createState() => _InquilinosScreenState();
}

class _InquilinosScreenState extends State<InquilinosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InquilinosProvider>(context, listen: false).fetchInquilinos();
    });
  }

  /// Helper para la pastilla de estado activo según contratos_vigentes (Guía Técnica)
  Widget _buildActiveStatusBadge(InquilinoModel inquilino) {
    final int vigentes = inquilino.contratosVigentes;
    final bool isActive = vigentes > 0;
    final Color badgeColor = isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? '$vigentes activo(s)' : '0 contratos',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showInquilinoDetailsModal(InquilinoModel inq) {
    // Asegurar que los contratos estén cargados para relacionarlos
    final contratosProvider = Provider.of<ContratosProvider>(context, listen: false);
    if (contratosProvider.contratos.isEmpty && !contratosProvider.isLoading) {
      contratosProvider.fetchContratos();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InquilinoDetailSheet(inquilino: inq),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<InquilinosProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Barra de Búsqueda Instantánea en Memoria
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: CustomSearchBar(
              hintText: 'Buscar cliente por nombre o identificación...',
              initialValue: provider.searchQuery,
              onSearch: (q) => provider.filtrarInquilinos(q),
            ),
          ),

          // Lista de Inquilinos con Pull-to-Refresh y KPIs en cabecera
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchInquilinos(),
              child: _buildBody(provider, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(InquilinosProvider provider, bool isDark) {
    if (provider.isLoading && provider.todosLosInquilinos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.todosLosInquilinos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Error al cargar el directorio',
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
                onPressed: () => provider.fetchInquilinos(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final lista = provider.inquilinosFiltrados;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // -------------------------------------------------------------
        // Tarjetas KPI del Directorio
        // -------------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: KpiMetricCard(
                title: 'Total Clientes',
                value: '${provider.totalClientes}',
                subtitle: 'Directorio maestro',
                icon: Icons.people_alt_rounded,
                accentColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiMetricCard(
                title: 'Clientes Activos',
                value: '${provider.clientesActivos}',
                subtitle: '${provider.clientesInactivos} sin contratos vigentes',
                icon: Icons.check_circle_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Título de Sección
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Directorio de Clientes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${lista.length} de ${provider.totalClientes}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded, size: 48, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  const SizedBox(height: 10),
                  Text(
                    'No se encontraron coincidencias para "${provider.searchQuery}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...lista.map((inq) => _buildInquilinoCard(inq, isDark)),
      ],
    );
  }

  Widget _buildInquilinoCard(InquilinoModel item, bool isDark) {
    final initials = item.nombresRazonSocial.isNotEmpty
        ? item.nombresRazonSocial.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'IN';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showInquilinoDetailsModal(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con logo corporativo o iniciales
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  color: item.isActivo
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  child: (item.logo != null && item.logo!.isNotEmpty)
                      ? Image.network(
                          item.logo!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: item.isActivo
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: item.isActivo
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Datos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.nombresRazonSocial,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildActiveStatusBadge(item),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${item.identificacion}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    if (item.telefono != null && item.telefono!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            item.telefono!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal deslizable interactivo que revela los contratos activos, montos y propiedades al hacer scroll hacia arriba
class _InquilinoDetailSheet extends StatelessWidget {
  final InquilinoModel inquilino;

  const _InquilinoDetailSheet({required this.inquilino});

  Widget _buildActiveBadge(InquilinoModel inq) {
    final int vigentes = inq.contratosVigentes;
    final bool isActive = vigentes > 0;
    final Color badgeColor = isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? '$vigentes activo(s)' : '0 contratos',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMini({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(InquilinoModel inq, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withOpacity(0.6) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          if (inq.telefono != null && inq.telefono!.isNotEmpty)
            _buildContactRow(
              icon: Icons.phone_rounded,
              label: inq.telefono!,
              isDark: isDark,
            ),
          if (inq.email != null && inq.email!.isNotEmpty) ...[
            if (inq.telefono != null && inq.telefono!.isNotEmpty) const SizedBox(height: 6),
            _buildContactRow(
              icon: Icons.email_rounded,
              label: inq.email!,
              isDark: isDark,
            ),
          ],
          if (inq.direccion != null && inq.direccion!.isNotEmpty) ...[
            if ((inq.telefono != null && inq.telefono!.isNotEmpty) || (inq.email != null && inq.email!.isNotEmpty))
              const SizedBox(height: 6),
            _buildContactRow(
              icon: Icons.location_on_rounded,
              label: inq.direccion!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContractItemCard(BuildContext context, ContratoModel c, bool isDark) {
    final hasMultiple = c.tieneMultiplesInmuebles;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContratoDetailScreen(
                contratoId: c.id,
                initialContrato: c,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Número de contrato + Badge de estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.numeroContrato ?? 'Contrato #${c.id}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Vigente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Inmueble(s) asignados
              Row(
                children: [
                  Icon(
                    hasMultiple ? Icons.apartment_rounded : Icons.warehouse_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.resumenInmuebles,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (c.metrajeTotal > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${AppFormatters.number(c.metrajeTotal)} m²',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Monto y Vigencia
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Canon Pactado',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            AppFormatters.currency(c.valorMensualizado),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            ' / mes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Vencimiento',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.fechaFin.isNotEmpty ? c.fechaFin : 'Indefinido',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF2563EB),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.62, 0.94],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Consumer<ContratosProvider>(
            builder: (context, contratosProvider, _) {
              // Obtener contratos vinculados a este inquilino
              final allContracts = contratosProvider.contratos.where((c) {
                if (c.inquilinoId != null && inquilino.id != 0 && c.inquilinoId == inquilino.id) {
                  return true;
                }
                if (c.identificacionInquilino != null &&
                    c.identificacionInquilino!.trim().isNotEmpty &&
                    inquilino.identificacion.trim().isNotEmpty &&
                    c.identificacionInquilino!.trim().toLowerCase() == inquilino.identificacion.trim().toLowerCase()) {
                  return true;
                }
                return c.nombresInquilino.trim().toLowerCase() == inquilino.nombresRazonSocial.trim().toLowerCase();
              }).toList();

              final activeContracts = allContracts.where((c) => c.isVigente).toList();
              final double totalRentaMensual = activeContracts.fold(0.0, (acc, c) => acc + c.valorMensualizado);
              final double totalMetraje = activeContracts.fold(0.0, (acc, c) => acc + c.metrajeTotal);

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cabecera del Inquilino
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo o Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 52,
                          height: 52,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          child: (inquilino.logo != null && inquilino.logo!.isNotEmpty)
                              ? Image.network(
                                  inquilino.logo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.business_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 28,
                                  ),
                                )
                              : const Icon(
                                  Icons.business_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 28,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inquilino.nombresRazonSocial,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID / RUC: ${inquilino.identificacion}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildActiveBadge(inquilino),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Resumen Financiero del Inquilino
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpiMini(
                          label: 'Renta Activa',
                          value: AppFormatters.currency(totalRentaMensual),
                          subtitle: 'Mensual',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        _buildKpiMini(
                          label: 'Área Ocupada',
                          value: '${AppFormatters.number(totalMetraje)} m²',
                          subtitle: 'Arrendado',
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        _buildKpiMini(
                          label: 'Contratos',
                          value: '${activeContracts.length}',
                          subtitle: 'Vigentes',
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información de Contacto Rápida
                  if ((inquilino.telefono != null && inquilino.telefono!.isNotEmpty) ||
                      (inquilino.email != null && inquilino.email!.isNotEmpty) ||
                      (inquilino.direccion != null && inquilino.direccion!.isNotEmpty)) ...[
                    _buildContactSection(inquilino, isDark),
                    const SizedBox(height: 16),
                  ],

                  // Encabezado de la sección de Contratos Activos con pista visual de scroll
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contratos Activos (${activeContracts.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.keyboard_double_arrow_up_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Desliza para ver más',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lista de Contratos Activos
                  if (contratosProvider.isLoading && activeContracts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (activeContracts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            size: 38,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin contratos activos registrados actualmente',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...activeContracts.map((c) => _buildContractItemCard(context, c, isDark)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

