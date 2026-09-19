import 'package:flutter/material.dart';

/// Banner Panorámico Ejecutivo para el Dashboard de Eslive.
/// Muestra limpiamente la imagen corporativa del portafolio (red o asset local).
class PortfolioHeroBanner extends StatelessWidget {
  final String? networkImageUrl;
  final String defaultAssetImage;
  final double height;

  const PortfolioHeroBanner({
    super.key,
    this.networkImageUrl,
    this.defaultAssetImage = 'assets/images/portfolio_hero_banner.jpg',
    this.height = 145,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
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
        child: (networkImageUrl != null && networkImageUrl!.isNotEmpty)
            ? Image.network(
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
            : Image.asset(
                defaultAssetImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
      ),
    );
  }
}
