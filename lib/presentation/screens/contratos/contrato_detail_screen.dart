import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/contrato_model.dart';
import '../../../logic/contratos_provider.dart';

/// Detalle financiero y relacional de un Contrato (/contratos/{id}) con soporte multipropiedad.
class ContratoDetailScreen extends StatefulWidget {
  final int contratoId;
  final ContratoModel? initialContrato;

  const ContratoDetailScreen({
    super.key,
    required this.contratoId,
    this.initialContrato,
  });

  @override
  State<ContratoDetailScreen> createState() => _ContratoDetailScreenState();
}

class _ContratoDetailScreenState extends State<ContratoDetailScreen> {
  ContratoModel? _contrato;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contrato = widget.initialContrato;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<ContratosProvider>(context, listen: false);
    final result = await provider.getDetalle(widget.contratoId);

    if (!mounted) return;
    setState(() {
      if (result != null) {
        if (widget.initialContrato != null && widget.initialContrato!.tieneMultiplesInmuebles) {
          _contrato = widget.initialContrato!.mergeWith(result);
        } else {
          _contrato = result;
        }
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = _contrato;

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.numeroContrato != null ? 'Contrato #${item!.numeroContrato}' : 'Detalle de Contrato'),
      ),
      body: _isLoading && item == null
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? const Center(child: Text('No se pudo cargar el contrato'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tarjeta Financiera Principal (Monto Acumulado)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Canon de Arrendamiento',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                    ),
                                    if (item.tieneMultiplesInmuebles) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Acumulado',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.frecuenciaPago.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppFormatters.currency(item.valorPactado),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Día preferido de pago: ${item.diaPagoPreferido} de cada mes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inquilino Relacionado
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos del Inquilino / Arrendatario',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 14),
                            _buildRow(Icons.person_rounded, 'Nombre / Razón Social', item.nombresInquilino, isDark),
                            _buildRow(Icons.badge_rounded, 'Identificación', item.identificacionInquilino, isDark),
                            if (item.telefonoInquilino != null && item.telefonoInquilino!.isNotEmpty)
                              _buildRow(Icons.phone_rounded, 'Teléfono', item.telefonoInquilino, isDark),
                            if (item.emailInquilino != null && item.emailInquilino!.isNotEmpty)
                              _buildRow(Icons.email_rounded, 'Correo', item.emailInquilino, isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sección de Inmuebles Asociados
                    if (item.tieneMultiplesInmuebles) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Inmuebles Asociados (${item.cantidadInmuebles})',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.cantidadInmuebles} unidades',
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...item.inmueblesAsociados.map((inm) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.warehouse_rounded, size: 18, color: Color(0xFF2563EB)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              inm.nombre,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${inm.metraje > 0 ? AppFormatters.area(inm.metraje) : 'Metraje N/D'}${inm.propietario != null && inm.propietario!.isNotEmpty ? ' • ${inm.propietario}' : ''}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (inm.valor > 0)
                                        Text(
                                          AppFormatters.currency(inm.valor),
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Área Total: ${AppFormatters.area(item.totalMetraje)}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    'Suma: ${AppFormatters.currency(item.valorPactado)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (item.inmuebleNombre != null && item.inmuebleNombre!.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Inmueble Asociado',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 14),
                              _buildRow(Icons.apartment_rounded, 'Inmueble', item.inmuebleNombre, isDark),
                              if (item.metraje != null)
                                _buildRow(Icons.square_foot_rounded, 'Metraje', '${item.metraje} m²', isDark),
                              if (item.propietario != null && item.propietario!.isNotEmpty)
                                _buildRow(Icons.business_rounded, 'Propietario', item.propietario, isDark),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Vigencia y Fechas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vigencia del Contrato',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 14),
                            _buildRow(Icons.event_available_rounded, 'Fecha de Inicio', AppFormatters.date(item.fechaInicio), isDark),
                            _buildRow(Icons.event_busy_rounded, 'Fecha de Vencimiento', AppFormatters.date(item.fechaFin), isDark),
                            _buildRow(
                              Icons.hourglass_bottom_rounded,
                              'Tiempo Restante',
                              '${item.diasRestantes} días',
                              isDark,
                            ),
                            if (item.observaciones != null && item.observaciones!.isNotEmpty) ...[
                              const Divider(height: 20),
                              Text(
                                'Observaciones:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.observaciones!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRow(IconData icon, String label, String? value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
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
