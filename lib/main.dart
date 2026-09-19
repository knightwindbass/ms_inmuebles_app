import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/storage/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/contratos_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/inmuebles_repository.dart';
import 'data/repositories/inquilinos_repository.dart';
import 'data/repositories/tenant_repository.dart';
import 'logic/auth_provider.dart';
import 'logic/contratos_provider.dart';
import 'logic/dashboard_provider.dart';
import 'logic/inmuebles_provider.dart';
import 'logic/inquilinos_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // Inicializar almacenamiento de sesión
  final sessionStorage = await SessionStorage.init();

  runApp(
    MultiProvider(
      providers: [
        // Proveedor de Autenticación y Conexión Multi-Tenant
        ChangeNotifierProvider(
          create: (_) => AuthProvider(sessionStorage),
        ),

        // Inyección de Repositorios que dependen del cliente HTTP activo
        ProxyProvider<AuthProvider, DashboardRepository>(
          update: (_, auth, __) => DashboardRepository(auth.apiClient),
        ),
        ProxyProvider<AuthProvider, InmueblesRepository>(
          update: (_, auth, __) => InmueblesRepository(auth.apiClient),
        ),
        ProxyProvider<AuthProvider, ContratosRepository>(
          update: (_, auth, __) => ContratosRepository(auth.apiClient),
        ),
        ProxyProvider<AuthProvider, InquilinosRepository>(
          update: (_, auth, __) => InquilinosRepository(auth.apiClient),
        ),
        ProxyProvider<AuthProvider, TenantRepository>(
          update: (_, auth, __) => TenantRepository(auth.apiClient),
        ),

        // Proveedores de Estado de la Aplicación
        ChangeNotifierProxyProvider2<DashboardRepository, InmueblesRepository, DashboardProvider>(
          create: (context) => DashboardProvider(
            context.read<DashboardRepository>(),
            context.read<InmueblesRepository>(),
          ),
          update: (_, dashRepo, inmRepo, prev) => prev ?? DashboardProvider(dashRepo, inmRepo),
        ),
        ChangeNotifierProxyProvider<InmueblesRepository, InmueblesProvider>(
          create: (context) => InmueblesProvider(context.read<InmueblesRepository>()),
          update: (_, repo, prev) => prev ?? InmueblesProvider(repo),
        ),
        ChangeNotifierProxyProvider<ContratosRepository, ContratosProvider>(
          create: (context) => ContratosProvider(context.read<ContratosRepository>()),
          update: (_, repo, prev) => prev ?? ContratosProvider(repo),
        ),
        ChangeNotifierProxyProvider<InquilinosRepository, InquilinosProvider>(
          create: (context) => InquilinosProvider(context.read<InquilinosRepository>()),
          update: (_, repo, prev) => prev ?? InquilinosProvider(repo),
        ),
      ],
      child: const MSInmueblesApp(),
    ),
  );
}

/// Widget raíz de la aplicación MS Inmuebles SaaS.
class MSInmueblesApp extends StatelessWidget {
  const MSInmueblesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eslive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
