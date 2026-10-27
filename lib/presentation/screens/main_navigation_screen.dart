import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../data/services/app_update_service.dart';
import '../../logic/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'inmuebles/inmuebles_screen.dart';
import 'contratos/contratos_screen.dart';
import 'inquilinos/inquilinos_screen.dart';
import 'tenant_setup_screen.dart';
import 'dashboard/deuda_dashboard_screen.dart';
import 'dashboard/pareto_top_ten_screen.dart';
import 'dashboard/terrenos_dashboard_screen.dart';

/// Contenedor principal con barra de navegación inferior minimalista.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndShowPrompt(context, manualCheck: false);
    });
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    InmueblesScreen(),
    ContratosScreen(),
    InquilinosScreen(),
  ];

  void _showTenantOptions() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Sesión SaaS Multi-Tenant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2563EB),
                    child: Icon(Icons.business_rounded, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    auth.tenantId,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    auth.baseUrl,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.system_update_rounded, color: Color(0xFF0D9488)),
                  title: const Text('Buscar Actualizaciones'),
                  subtitle: Text(
                    'Versión instalada: v${ApiConstants.currentAppVersion} (Build ${ApiConstants.currentBuildNumber})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    AppUpdateService.checkAndShowPrompt(context, manualCheck: true);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: const Text('Cambiar Tenant o Servidor'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TenantSetupScreen()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TenantSetupScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showToolsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151C2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Módulos y Herramientas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gestión estratégica y financiera del portafolio',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. HERRAMIENTA DESTACADA: GESTIÓN DE DEUDA & PASIVOS
                _buildToolCard(
                  context: context,
                  title: 'Gestión de Deuda & Pasivos',
                  subtitle: 'Cuadro de riesgos, cuotas bancarias, amortización y tramos',
                  badgeText: 'Corte Septiembre 2026 • \$43.25 M',
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF0D9488),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeudaDashboardScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // 2. HERRAMIENTA: TOP 10 PARETO DE RENTA
                _buildToolCard(
                  context: context,
                  title: 'Top 10 Pareto (Renta 80/20)',
                  subtitle: 'Concentración de facturación agrupada por Razón Social matriz',
                  badgeText: 'Análisis Pareto',
                  icon: Icons.leaderboard_rounded,
                  accentColor: const Color(0xFFEAB308),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParetoTopTenScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // 3. HERRAMIENTA: BANCO DE TIERRAS & TERRENOS
                _buildToolCard(
                  context: context,
                  title: 'Dashboard de Terrenos',
                  subtitle: 'Land banking, áreas zonificadas, lotes y valuación',
                  badgeText: 'Tenencia Territorial',
                  icon: Icons.landscape_rounded,
                  accentColor: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TerrenosDashboardScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // 4. CRUCE OPERATIVO: FLUJO NETO
                _buildToolCard(
                  context: context,
                  title: 'Flujo Financiero Neto (Rentas vs Deuda)',
                  subtitle: 'Cruce entre rentas recaudadas (\$443K) y servicio de pasivos (\$450K)',
                  badgeText: 'Net Cash Flow',
                  icon: Icons.price_change_rounded,
                  accentColor: const Color(0xFF6366F1),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeudaDashboardScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                auth.tenantId,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Eslive',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            tooltip: 'Configuración de Tenant',
            onPressed: _showTenantOptions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
            _showToolsBottomSheet(context);
          }
        },
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! < -6) {
            _showToolsBottomSheet(context);
          }
        },
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: const Color(0xFF2563EB),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF2563EB),
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.white, size: 24);
              }
              return IconThemeData(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: isDark ? const Color(0xFF151C2C) : Colors.white,
            elevation: 2,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
                label: 'Reportes',
              ),
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment_rounded, color: Colors.white),
                label: 'Inmuebles',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description_rounded, color: Colors.white),
                label: 'Contratos',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt_rounded, color: Colors.white),
                label: 'Inquilinos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
