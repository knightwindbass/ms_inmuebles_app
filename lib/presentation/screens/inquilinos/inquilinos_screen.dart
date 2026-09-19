import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/inquilino_model.dart';
import '../../../logic/inquilinos_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/kpi_metric_card.dart';

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (inq.logo != null && inq.logo!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          child: Image.network(
                            inq.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inq.nombresRazonSocial,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Identificación: ${inq.identificacion}',
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
                    _buildActiveStatusBadge(inq),
                  ],
                ),
                const Divider(height: 24),
                if (inq.telefono != null && inq.telefono!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB)),
                    title: const Text('Teléfono de Contacto', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    subtitle: Text(inq.telefono!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                if (inq.email != null && inq.email!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_rounded, color: Color(0xFF2563EB)),
                    title: const Text('Correo Electrónico', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    subtitle: Text(inq.email!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                if (inq.direccion != null && inq.direccion!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB)),
                    title: const Text('Dirección / Domicilio', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    subtitle: Text(inq.direccion!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
              ],
            ),
          ),
        );
      },
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
