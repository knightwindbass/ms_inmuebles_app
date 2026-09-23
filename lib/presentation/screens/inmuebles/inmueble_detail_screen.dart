import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/inmueble_model.dart';
import '../../../logic/inmuebles_provider.dart';
import '../../widgets/status_badge.dart';

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
    final result = await provider.getDetalle(widget.inmuebleId);

    if (!mounted) return;
    setState(() {
      if (result != null) {
        _inmueble = result;
      }
      _isLoading = false;
    });
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
        final contrato = item.contratos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      contrato.nombresInquilino,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      AppFormatters.currency(contrato.valorPactado),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Vigencia: ${AppFormatters.date(contrato.fechaInicio)} - ${AppFormatters.date(contrato.fechaFin)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
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
