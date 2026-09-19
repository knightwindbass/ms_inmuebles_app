import 'package:flutter/material.dart';

/// Banner Panorámico Ejecutivo para el Dashboard de Eslive.
/// Soporta imagen local predeterminada y URLs remotas dinámicas por Tenant.
class PortfolioHeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? networkImageUrl;
  final String defaultAssetImage;

  const PortfolioHeroBanner({
    super.key,
    this.title = 'Portafolio en movimiento',
    this.subtitle = 'Espacios para un Ecuador que avanza.',
    this.networkImageUrl,
    this.defaultAssetImage = 'assets/images/portfolio_hero_banner.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Fondo degradado corporativo por defecto
            Color(0xFF1E293B),
            Color(0xFF0B1329),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de Fondo (Red o Asset Local con fallback)
            if (networkImageUrl != null && networkImageUrl!.isNotEmpty)
              Image.network(
                networkImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Image.asset(
                  defaultAssetImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            else
              Image.asset(
                defaultAssetImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),

            // Capa de Gradiente Oscuro para Legibilidad Superior del Texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.82),
                    Colors.black.withValues(alpha: 0.58),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),

            // Textos y Contenido Corporativo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                      ],
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
}
