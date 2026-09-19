import 'package:flutter/material.dart';

/// Tarjeta Inteligente Ejecutiva (Smart KPI Card) para el Dashboard de Eslive.
class SmartKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? valueSuffix;
  final String? trendBadge;
  final String? trendContext;
  final String? subtitle;
  final bool isSubtitleHighlighted;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isOutlinedIcon;

  const SmartKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.valueSuffix,
    this.trendBadge,
    this.trendContext,
    this.subtitle,
    this.isSubtitleHighlighted = false,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isOutlinedIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Fila 1: Icono + Título
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isOutlinedIcon
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                      : iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: isOutlinedIcon
                      ? Border.all(color: const Color(0xFF94A3B8), width: 1.5)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isOutlinedIcon
                      ? (isDark ? Colors.white : const Color(0xFF475569))
                      : iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Fila 2: Valor Principal y Sufijo
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  valueSuffix!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Fila 3: Indicador de Tendencia o Subtítulo
          if (trendBadge != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trendBadge!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                if (trendContext != null)
                  Text(
                    trendContext!,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
              ],
            )
          else if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSubtitleHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: isSubtitleHighlighted
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
