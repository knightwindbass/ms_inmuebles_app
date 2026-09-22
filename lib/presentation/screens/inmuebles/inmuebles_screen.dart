import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/inmueble_model.dart';
import '../../../logic/inmuebles_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/status_badge.dart';
import 'inmueble_detail_screen.dart';

/// Pantalla de Inventario y Buscador de Inmuebles con soporte jerárquico (/inmuebles).
class InmueblesScreen extends StatefulWidget {
  const InmueblesScreen({super.key});

  @override
  State<InmueblesScreen> createState() => _InmueblesScreenState();
}

class _InmueblesScreenState extends State<InmueblesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InmueblesProvider>(context, listen: false).fetchInmuebles();
    });
  }

  void _showSortModal(InmueblesProvider provider) {
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
                'Ordenar Inmuebles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: const Text('Mayor a menor renta (renta_desc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenRentaDesc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenRentaDesc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Menor a mayor renta (renta_asc)'),
                trailing: provider.selectedOrden == ApiConstants.ordenRentaAsc
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.setOrden(ApiConstants.ordenRentaAsc);
                  Navigator.pop(ctx);
                },
              ),
              if (provider.selectedOrden != null)
                ListTile(
                  leading: const Icon(Icons.clear_rounded, color: Color(0xFFEF4444)),
                  title: const Text('Limpiar orden', style: TextStyle(color: Color(0xFFEF4444))),
                  onTap: () {
                    provider.setOrden(null);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<InmueblesProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda con Debounce
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    hintText: 'Buscar por nombre, dirección o ciudad...',
                    initialValue: provider.searchQuery,
                    onSearch: (query) => provider.setSearchQuery(query),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(
                    Icons.sort_rounded,
                    color: provider.selectedOrden != null ? const Color(0xFF2563EB) : null,
                  ),
                  tooltip: 'Ordenar',
                  onPressed: () => _showSortModal(provider),
                ),
              ],
            ),
          ),

          // Filtros Rápidos (Chips: f_estado y f_tipo)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Filtros de Estado (f_estado)
                ...ApiConstants.estadosInmueble.map((estado) {
                  final isSelected = provider.selectedEstado?.toLowerCase() == estado.toLowerCase();
                  final stateColor = AppTheme.getColorForEstado(estado);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle),
                      ),
                      label: Text(estado[0].toUpperCase() + estado.substring(1)),
                      onSelected: (_) => provider.setEstadoFilter(estado),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                // Filtros de Tipología (f_tipo)
                ...ApiConstants.tiposInmueble.map((tipo) {
                  final isSelected = provider.selectedTipo?.toLowerCase() == tipo.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(AppTheme.getIconForType(tipo), size: 14),
                      label: Text(tipo),
                      onSelected: (_) => provider.setTipoFilter(tipo),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Resumen Rápido de Auditoría y Contador de Resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            provider.hasFilters
                                ? '${provider.inmuebles.length} inmuebles'
                                : '${provider.topLevelInmuebles.length} matrices • ${provider.inmuebles.length} total',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Área: ${AppFormatters.area(provider.totalAreaAudit)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        if (provider.totalRentaRentados > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Renta: ${AppFormatters.currency(provider.totalRentaRentados)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (provider.hasFilters)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => provider.clearFilters(),
                    child: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),

          // Lista de Inmuebles (Plana si busca, Jerárquica si navega)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchInmuebles(),
              child: _buildInmueblesList(provider, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInmueblesList(InmueblesProvider provider, bool isDark) {
    if (provider.isLoading && provider.inmuebles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.inmuebles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Error al consultar inmuebles',
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
                onPressed: () => provider.fetchInmuebles(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.inmuebles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment_rounded, size: 54, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'No se encontraron inmuebles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            if (provider.hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => provider.clearFilters(),
                child: const Text('Limpiar todos los filtros'),
              ),
            ],
          ],
        ),
      );
    }

    // 1. MODO BÚSQUEDA ACTIVA: Vista Plana
    if (provider.hasFilters) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.inmuebles.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.inmuebles.length) {
            return _buildAuditTotalsCard(provider, isDark);
          }
          final inmueble = provider.inmuebles[index];
          return _buildInmuebleCard(inmueble, isDark);
        },
      );
    }

    // 2. MODO NAVEGACIÓN: Vista Jerárquica (Matrices con sub-unidades colapsables)
    final topLevel = provider.topLevelInmuebles;
    final childrenMap = provider.groupedChildren;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: topLevel.length + 1,
      itemBuilder: (context, index) {
        if (index == topLevel.length) {
          return _buildAuditTotalsCard(provider, isDark);
        }
        final parent = topLevel[index];
        final children = childrenMap[parent.id] ?? [];

        if (children.isNotEmpty) {
          return _buildParentExpansionCard(parent, children, isDark);
        }

        return _buildInmuebleCard(parent, isDark);
      },
    );
  }

  /// Renderiza un Complejo Matriz con sus sub-unidades agrupadas en un ExpansionTile
  Widget _buildParentExpansionCard(InmuebleModel parent, List<InmuebleModel> children, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            AppTheme.getIconForType(parent.tipo),
            color: const Color(0xFF2563EB),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                parent.nombre,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            StatusBadge(status: parent.estado, isSmall: true),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${children.length} sub-unidades hijas',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              Text(
                AppFormatters.currency(parent.valorRentaBase),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        children: [
          Container(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sub-unidades del complejo:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InmuebleDetailScreen(inmuebleId: parent.id, inmuebleInitial: parent),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver Ficha Matriz →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...children.map((child) => _buildChildTile(child, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de sub-unidad dentro de la matriz
  Widget _buildChildTile(InmuebleModel child, bool isDark) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          AppTheme.getIconForType(child.tipo),
          size: 18,
          color: const Color(0xFF64748B),
        ),
        title: Text(
          child.nombre,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${child.tipo}${child.metraje != null ? ' • ${AppFormatters.area(child.metraje)}' : ''}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormatters.currency(child.valorRentaBase),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: child.estado, isSmall: true),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InmuebleDetailScreen(inmuebleId: child.id, inmuebleInitial: child),
            ),
          );
        },
      ),
    );
  }

  /// Tarjeta estándar para propiedades individuales o modo búsqueda plana
  Widget _buildInmuebleCard(InmuebleModel inmueble, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InmuebleDetailScreen(inmuebleId: inmueble.id, inmuebleInitial: inmueble),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            AppTheme.getIconForType(inmueble.tipo),
                            color: const Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inmueble.nombre,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    inmueble.tipo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                  if (inmueble.metraje != null && inmueble.metraje! > 0)
                                    Text(
                                      '• ${AppFormatters.area(inmueble.metraje)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  if (inmueble.propiedadPadreId != null && inmueble.propiedadPadreId! > 0)
                                    const Text(
                                      '• Sub-unidad',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusBadge(status: inmueble.estado),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            inmueble.direccion != null && inmueble.direccion!.isNotEmpty
                                ? '${inmueble.direccion}${inmueble.ciudad != null ? ', ${inmueble.ciudad}' : ''}'
                                : (inmueble.ciudad ?? 'Sin ubicación registrada'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.currency(inmueble.valorRentaBase),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de Auditoría de Totales al final de la lista de inmuebles
  Widget _buildAuditTotalsCard(InmueblesProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header de la Tarjeta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                  : const Color(0xFFEFF6FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totales de Auditoría',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        provider.hasFilters
                            ? provider.resumenFiltrosActivos
                            : 'Portafolio Completo (${provider.inmuebles.length} registros)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${provider.inmuebles.length} uds',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cuerpo de Métricas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAuditRow(
                  label: 'Área Total Listada',
                  value: AppFormatters.area(provider.totalAreaAudit),
                  subtitle: (!provider.hasFilters && provider.totalAreaFilasBrutas != provider.totalAreaAudit)
                      ? 'Área bruta en filas: ${AppFormatters.area(provider.totalAreaFilasBrutas)}'
                      : null,
                  icon: Icons.square_foot,
                  iconColor: const Color(0xFF2563EB),
                  isDark: isDark,
                  isBold: true,
                ),
                const Divider(height: 18),
                _buildAuditRow(
                  label: 'Renta Mensual (Rentados)',
                  value: AppFormatters.currency(provider.totalRentaRentados),
                  subtitle: (provider.totalRentaFilasBrutas != provider.totalRentaRentados)
                      ? '${provider.totalRentados} leasables • Renta bruta en filas: ${AppFormatters.currency(provider.totalRentaFilasBrutas)}'
                      : '${provider.totalRentados} inmuebles con contrato activo',
                  icon: Icons.monetization_on_outlined,
                  iconColor: const Color(0xFF10B981),
                  valueColor: const Color(0xFF10B981),
                  isDark: isDark,
                  isBold: true,
                ),
                const Divider(height: 18),
                _buildAuditRow(
                  label: r'Rendimiento Promedio $/m²',
                  value: '${AppFormatters.currency(provider.valorPromedioM2Audit)}/m²',
                  subtitle: 'Sobre ${AppFormatters.area(provider.areaRentadaAudit)} rentados',
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
                const Divider(height: 18),
                _buildAuditRow(
                  label: 'Canon Base Potencial (Total)',
                  value: AppFormatters.currency(provider.totalRentaBasePortafolio),
                  subtitle: 'Suma cánones de rentados + disponibles',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
                const Divider(height: 18),
                // Conteo de Estados
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAuditStateChip(
                      label: 'Rentados',
                      count: provider.totalRentados,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    _buildAuditStateChip(
                      label: 'Disponibles',
                      count: provider.totalDisponibles,
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                    if (provider.totalOtrosEstados > 0)
                      _buildAuditStateChip(
                        label: 'Otros',
                        count: provider.totalOtrosEstados,
                        color: const Color(0xFF6B7280),
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    required bool isDark,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditStateChip({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
