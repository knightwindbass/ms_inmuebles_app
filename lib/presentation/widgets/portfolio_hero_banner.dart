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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
            // Imagen de Fondo (Red o Asset Local)
            if (networkImageUrl != null && networkImageUrl!.isNotEmpty)
              Image.network(
                networkImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  defaultAssetImage,
                  fit: BoxFit.cover,
                ),
              )
            else
              Image.asset(
                defaultAssetImage,
                fit: BoxFit.cover,
              ),

            // Capa de Gradiente Oscuro para Legibilidad Superior
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.78),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.25),
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
                      color: Colors.white.withOpacity(0.92),
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
