import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/deuda_inmobiliaria_model.dart';

/// Pantalla de Detalle Ejecutivo de Proyecto de Deuda Inmobiliaria
/// Replicando la experiencia y estética visual del prototipo GenUI / ChatGPT.
class ProyectoDeudaDetailScreen extends StatefulWidget {
  final ProyectoDeudaModel proyecto;

  const ProyectoDeudaDetailScreen({
    super.key,
    required this.proyecto,
  });

  @override
  State<ProyectoDeudaDetailScreen> createState() => _ProyectoDeudaDetailScreenState();
}

class _ProyectoDeudaDetailScreenState extends State<ProyectoDeudaDetailScreen> {
  bool _showParts = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.proyecto;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final original = p.original;
    final balance = p.balance;
    final capitalAmortizado = p.capitalReducido;
    final pctAmortizado = p.porcentajeReducido;
    final totalLetras = p.total;
    final pagadas = p.paid;
    final pendientes = (totalLetras != null && pagadas != null) ? (totalLetras - pagadas) : null;
    final pctLetras = (totalLetras != null && totalLetras > 0 && pagadas != null)
        ? (pagadas / totalLetras * 100)
        : 0.0;

    const colorTeal = Color(0xFF0D9488);
    const colorBlue = Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banco emisor badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Text(
                p.bank,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card principal de Saldo Pendiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SALDO PENDIENTE ACTUAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.currency(balance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monto original: ${AppFormatters.currency(original)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Grid: Capital amortizado & % amortizado
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAPITAL AMORTIZADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.currency(capitalAmortizado),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '% AMORTIZADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${pctAmortizado.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de progreso Teal (#0D9488)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 10,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (pctAmortizado / 100).clamp(0.0, 1.0),
                      child: Container(color: colorTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Avance de reducción del capital respecto al monto original',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Cuota mensual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  Text(
                    'CUOTA MENSUAL REGISTRADA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.monthly != null
                        ? AppFormatters.currency(p.monthly!)
                        : 'Por confirmar tras consolidación',
                    style: TextStyle(
                      fontSize: p.monthly != null ? 22 : 16,
                      fontWeight: FontWeight.w800,
                      color: p.monthly != null
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Letras: Total / Pagadas / Pendientes + Barra Azul (#2563EB)
            if (totalLetras != null && pagadas != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Total letras',
                      value: '$totalLetras',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Pagadas',
                      value: '$pagadas',
                      valueColor: colorBlue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Pendientes',
                      value: '${pendientes ?? "—"}',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 9,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (pctLetras / 100).clamp(0.0, 1.0),
                    child: Container(color: colorBlue),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$pagadas de $totalLetras letras pagadas (${pctLetras.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorBlue,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // Grilla técnica (Fechas, Tasas)
            Row(
              children: [
                Expanded(
                  child: _buildDetailField(
                    label: 'Fecha de inicio',
                    value: p.start.isNotEmpty ? p.start : 'No registrada',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildDetailField(
                    label: 'Fecha de finalización',
                    value: p.end.isNotEmpty ? p.end : 'No confirmada',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailField(
                    label: 'Tasa de interés',
                    value: p.rate.isNotEmpty ? p.rate : 'Por confirmar',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildDetailField(
                    label: 'Intereses históricos',
                    value: 'Pendiente de conciliación',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nota de conciliación
            if (p.note.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTA DE CONCILIACIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.note,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Llamado especial para CEISA
            if (p.slugId == 'ceisa') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTRUCTURA DE CUOTA CEISA (\$63.224,01/MES)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRowPair('Letra Capital + Intereses:', '\$28.849,01', isDark),
                    const SizedBox(height: 4),
                    _buildRowPair('Letras Solo Intereses (36m):', '\$34.375,00', isDark),
                    const Divider(height: 16),
                    _buildRowPair('Total Mensual Referencial:', '\$63.224,01', isDark, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Acordeón de tramos individuales (Parts)
            if (p.parts != null && p.parts!.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => setState(() => _showParts = !_showParts),
                icon: Icon(
                  _showParts ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                ),
                label: Text(
                  _showParts
                      ? 'Ocultar operaciones individuales'
                      : 'Ver ${p.parts!.length} créditos individuales',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_showParts) ...[
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: p.parts!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final pt = p.parts![idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pt.descripcion,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monto:',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              Text(
                                AppFormatters.currency(pt.monto),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cuota mensual:',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              Text(
                                pt.cuota != null ? AppFormatters.currency(pt.cuota!) : 'Por confirmar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: pt.cuota != null ? colorTeal : Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vigencia:',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              Text(
                                '${pt.inicio} al ${pt.fin}',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                              ),
                            ],
                          ),
                          if (pt.pagadas != null && pt.total != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cuotas:',
                                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                                Text(
                                  '${pt.pagadas} / ${pt.total}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorBlue),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildRowPair(String label, String value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
