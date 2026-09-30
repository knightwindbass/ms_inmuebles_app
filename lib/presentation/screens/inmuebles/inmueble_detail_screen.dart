import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/contrato_model.dart';
import '../../../data/models/inmueble_model.dart';
import '../../../data/models/inquilino_model.dart';
import '../../../logic/contratos_provider.dart';
import '../../../logic/inmuebles_provider.dart';
import '../../../logic/inquilinos_provider.dart';
import '../../widgets/status_badge.dart';
import '../contratos/contrato_detail_screen.dart';

/// Ficha técnica detallada del inmueble con historial de contratos (/inmuebles/{id}).
class InmuebleDetailScreen extends StatefulWidget {
  final int inmuebleId;
  final InmuebleModel? inmuebleInitial;

  const InmuebleDetailScreen({
    super.key,
    required this.inmuebleId,
    this.inmuebleInitial,
  });

  @override
  State<InmuebleDetailScreen> createState() => _InmuebleDetailScreenState();
}

class _InmuebleDetailScreenState extends State<InmuebleDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InmuebleModel? _inmueble;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _inmueble = widget.inmuebleInitial;
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<InmueblesProvider>(context, listen: false);
    final contratosProvider = Provider.of<ContratosProvider>(context, listen: false);
    final inquilinosProvider = Provider.of<InquilinosProvider>(context, listen: false);

    // Cargar detalle del inmueble y precargar catálogos si aún están vacíos
    final futures = <Future>[
      provider.getDetalle(widget.inmuebleId),
    ];
    if (contratosProvider.todosLosContratos.isEmpty) {
      futures.add(contratosProvider.fetchContratos().catchError((_) {}));
    }
    if (inquilinosProvider.todosLosInquilinos.isEmpty) {
      futures.add(inquilinosProvider.fetchInquilinos().catchError((_) {}));
    }

    final results = await Future.wait(futures);
    final result = results[0] as InmuebleModel?;

    if (!mounted) return;
    setState(() {
      if (result != null) {
        _inmueble = result;
      }
      _isLoading = false;
    });
  }

  /// Resuelve la información completa del inquilino y referencia del contrato
  /// cruzando datos locales con el catálogo global en memoria.
  ContratoModel _resolveContrato(ContratoModel c) {
    var resolved = c;

    // 1. Cruzar con el catálogo de Contratos por ID o número de contrato
    try {
      final contratosProvider = Provider.of<ContratosProvider>(context, listen: false);
      final matchInContratos = contratosProvider.todosLosContratos.cast<ContratoModel?>().firstWhere(
        (tc) => tc != null && (
          (tc.id > 0 && tc.id == c.id) ||
          (tc.numeroContrato != null &&
              c.numeroContrato != null &&
              tc.numeroContrato!.trim().toLowerCase() == c.numeroContrato!.trim().toLowerCase())
        ),
        orElse: () => null,
      );

      if (matchInContratos != null) {
        resolved = resolved.mergeWith(matchInContratos);
      }
    } catch (_) {}

    // 2. Cruzar con el catálogo de Inquilinos si el nombre aún es 'Inquilino' o está vacío
    final isGenericTenant = resolved.nombresInquilino.isEmpty ||
        resolved.nombresInquilino.trim().toLowerCase() == 'inquilino';

    if (isGenericTenant) {
      try {
        final inquilinosProvider = Provider.of<InquilinosProvider>(context, listen: false);
        final matchInInquilinos = inquilinosProvider.todosLosInquilinos.cast<InquilinoModel?>().firstWhere(
          (inq) => inq != null && (
            (resolved.inquilinoId != null && resolved.inquilinoId! > 0 && inq.id == resolved.inquilinoId) ||
            (resolved.identificacionInquilino != null &&
                resolved.identificacionInquilino!.trim().isNotEmpty &&
                inq.identificacion.trim() == resolved.identificacionInquilino!.trim())
          ),
          orElse: () => null,
        );

        if (matchInInquilinos != null && matchInInquilinos.nombresRazonSocial.isNotEmpty) {
          resolved = resolved.copyWith(
            nombresInquilino: matchInInquilinos.nombresRazonSocial,
            identificacionInquilino: (resolved.identificacionInquilino != null && resolved.identificacionInquilino!.isNotEmpty)
                ? resolved.identificacionInquilino
                : matchInInquilinos.identificacion,
            emailInquilino: resolved.emailInquilino ?? matchInInquilinos.email,
            telefonoInquilino: resolved.telefonoInquilino ?? matchInInquilinos.telefono,
          );
        }
      } catch (_) {}
    }

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = _inmueble;

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.nombre ?? 'Detalle del Inmueble'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(text: 'Ficha Técnica'),
            Tab(text: 'Historial Contratos'),
          ],
        ),
      ),
      body: _isLoading && item == null
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? const Center(child: Text('No se pudo cargar la información'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFichaTecnica(item, isDark),
                    _buildHistorialContratos(item, isDark),
                  ],
                ),
    );
  }

  Widget _buildFichaTecnica(InmuebleModel item, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta Principal
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.tipo,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    StatusBadge(status: item.estado),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.nombre,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.currency(item.valorRentaBase),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const Text(
                  'Valor de renta base mensual',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Características y Ubicación
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Especificaciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.square_foot_rounded,
                  'Metraje / Área',
                  item.metraje != null && item.metraje! > 0 ? AppFormatters.area(item.metraje) : 'No especificado',
                  isDark,
                ),
                if (item.valorM2 > 0)
                  _buildInfoRow(
                    Icons.monetization_on_outlined,
                    'Valor por m²',
                    '\$${item.valorM2.toStringAsFixed(2)} / m²',
                    isDark,
                  ),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Propietario',
                  item.propietario ?? 'No asignado',
                  isDark,
                ),
                _buildInfoRow(
                  Icons.location_city_rounded,
                  'Ciudad / Provincia',
                  '${item.ciudad ?? '-'}${item.provincia != null ? ' / ${item.provincia}' : ''}',
                  isDark,
                ),
                _buildInfoRow(
                  Icons.place_outlined,
                  'Dirección',
                  item.direccion ?? 'Sin dirección registrada',
                  isDark,
                ),
                if (item.propiedadPadreId != null)
                  _buildInfoRow(
                    Icons.account_tree_rounded,
                    'Complejo Matriz',
                    'Sub-unidad de Matriz #${item.propiedadPadreId}',
                    isDark,
                  ),
              ],
            ),
          ),
        ),

        // Sub-unidades (si tiene)
        if (item.subunidades.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sub-Unidades Asociadas (${item.subunidades.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...item.subunidades.map(
                    (sub) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.meeting_room_outlined),
                      title: Text(sub.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(AppFormatters.currency(sub.valorRentaBase)),
                      trailing: StatusBadge(status: sub.estado, isSmall: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistorialContratos(InmuebleModel item, bool isDark) {
    if (item.contratos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 54, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text(
              'No hay contratos registrados para este inmueble',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: item.contratos.length,
      itemBuilder: (context, index) {
        final rawContrato = item.contratos[index];
        final contrato = _resolveContrato(rawContrato);

        final String refLabel = (contrato.numeroContrato != null && contrato.numeroContrato!.trim().isNotEmpty)
            ? contrato.numeroContrato!.trim()
            : (contrato.id > 0 ? 'CTR-${contrato.id}' : 'Contrato #${index + 1}');

        final bool isAuto = contrato.isAutoProjected;
        final int anios = contrato.aniosAntiguedad;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: contrato.id > 0
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ContratoDetailScreen(
                          contratoId: contrato.id,
                          initialContrato: contrato,
                        ),
                      ),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Referencia/Número + Estado + Canon de Renta
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Badge de Referencia / Número de Contrato
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tag_rounded,
                              size: 13,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              refLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de Estado
                      StatusBadge(status: contrato.estado, isSmall: true),
                      const Spacer(),
                      // Monto de Renta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.currency(contrato.valorPactado),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            contrato.frecuenciaPago == 'anual' ? '/ año' : '/ mes',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 2: Inquilino Real + RUC/Identificación
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            ),
                            if (contrato.identificacionInquilino != null &&
                                contrato.identificacionInquilino!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Identificación: ${contrato.identificacionInquilino}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (contrato.id > 0)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 10),

                  // Fila 3: Vigencia y Badges (Auto-renovación / Antigüedad)
                  Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Vigencia: ${AppFormatters.date(contrato.fechaInicio)} al ${AppFormatters.date(contrato.fechaFinEffective)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAuto) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.autorenew_rounded, size: 11, color: Color(0xFF6366F1)),
                              SizedBox(width: 3),
                              Text(
                                'Renov. Auto',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (anios > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$anios a. antig.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value != null && value.trim().isNotEmpty) ? value : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
