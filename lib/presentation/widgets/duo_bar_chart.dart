import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dashboard_kpi_model.dart';

/// Gráfico minimalista y responsivo de barras comparativas (Libres vs Ocupadas por tipología de inmueble).
class DuoBarChartWidget extends StatelessWidget {
  final List<DistribucionTipoEstado> data;

  const DuoBarChartWidget({
    super.key,
    required this.data,
  });

  IconData _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'edificio':
        return Icons.domain_rounded;
      case 'bodega':
        return Icons.warehouse_rounded;
      case 'local':
        return Icons.storefront_rounded;
      case 'oficina':
        return Icons.business_center_rounded;
      case 'terreno':
        return Icons.terrain_rounded;
      default:
        return Icons.apartment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay datos de distribución disponibles',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    // Calcular el valor máximo para escalar proporcionalmente las barras
    int maxVal = 1;
    for (final item in data) {
      if (item.libres > maxVal) maxVal = item.libres;
      if (item.ocupadas > maxVal) maxVal = item.ocupadas;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribución por Tipología',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ocupados (Rentados) vs Disponibles (Libres)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Leyenda Visual
            Row(
              children: [
                _buildLegendItem(
                  color: AppTheme.statusRentado,
                  label: 'Ocupados',
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  color: AppTheme.statusDisponible,
                  label: 'Disponibles',
                  isDark: isDark,
                ),
              ],
            ),
            const Divider(height: 28),

            // Filas de cada Tipología
            ...data.map((item) => _buildBarRow(item, maxVal, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildBarRow(DistribucionTipoEstado item, int maxVal, bool isDark) {
    final ocupadasFactor = maxVal > 0 ? (item.ocupadas / maxVal).clamp(0.0, 1.0) : 0.0;
    final libresFactor = maxVal > 0 ? (item.libres / maxVal).clamp(0.0, 1.0) : 0.0;
    final icon = _getIconForTipo(item.tipo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la tipología
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.tipo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.total} total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Fila Ocupados
          Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  'Ocupados:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ocupadasFactor,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.statusRentado),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: Text(
                  '${item.ocupadas}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.statusRentado,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Fila Disponibles
          Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  'Disponibles:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: libresFactor,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.statusDisponible),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: Text(
                  '${item.libres}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.statusDisponible,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
