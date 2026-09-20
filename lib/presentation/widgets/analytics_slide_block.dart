import 'package:flutter/material.dart';
import '../../data/models/dashboard_kpi_model.dart';
import 'duo_bar_chart.dart';
import 'rentabilidad_ubicacion_table.dart';

/// Bloque interactivo deslizable (Slide / Carrusel) que integra:
/// Slide 1: Distribución por Tipología (Gráfico comparativo dúo)
/// Slide 2: Rentabilidad por Ubicación (Tabla de complejos rentados y MRR)
class AnalyticsSlideBlock extends StatefulWidget {
  final List<DistribucionTipoEstado> distribucion;
  final List<RentabilidadUbicacion> rentabilidad;

  const AnalyticsSlideBlock({
    super.key,
    required this.distribucion,
    required this.rentabilidad,
  });

  @override
  State<AnalyticsSlideBlock> createState() => _AnalyticsSlideBlockState();
}

class _AnalyticsSlideBlockState extends State<AnalyticsSlideBlock> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_currentIndex == page) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra Superior de Pestañas / Selector + Indicadores de Slide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Selector Tipo Píldora Segmentada (Pestañas)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(
                          index: 0,
                          icon: Icons.bar_chart_rounded,
                          title: 'Tipología',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 4),
                        _buildTabButton(
                          index: 1,
                          icon: Icons.location_on_rounded,
                          title: 'Ubicación',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Indicadores de Página (Dots) y Pista de Deslizamiento
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      _buildDot(0, isDark),
                      const SizedBox(width: 4),
                      _buildDot(1, isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Vista Deslizable (PageView Horizontal)
            SizedBox(
              height: 385,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  // Slide 1: Gráfico de Distribución por Tipología
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: DuoBarChartWidget(
                      data: widget.distribucion,
                      showCard: false,
                    ),
                  ),

                  // Slide 2: Tabla de Rentabilidad por Ubicación
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: RentabilidadUbicacionTable(
                      data: widget.rentabilidad,
                      showCard: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _goToPage(index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, bool isDark) {
    final isSelected = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2563EB)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
