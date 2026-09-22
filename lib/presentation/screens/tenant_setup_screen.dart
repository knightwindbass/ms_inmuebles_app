import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../logic/auth_provider.dart';
import 'main_navigation_screen.dart';
import 'setup/qr_scanner_screen.dart';

/// Pantalla de configuración y autenticación Multi-Tenant con soporte de Tarjeta QR.
class TenantSetupScreen extends StatefulWidget {
  const TenantSetupScreen({super.key});

  @override
  State<TenantSetupScreen> createState() => _TenantSetupScreenState();
}

class _TenantSetupScreenState extends State<TenantSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _tenantIdController;
  bool _obscureApiKey = true;
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _baseUrlController = TextEditingController(
      text: auth.baseUrl.isNotEmpty ? auth.baseUrl : ApiConstants.defaultBaseUrl,
    );
    _apiKeyController = TextEditingController(text: auth.apiKey);
    _tenantIdController = TextEditingController(text: auth.tenantId);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _tenantIdController.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.of(context).push<QrCredentialsResult>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _showManualEntry = true;
        _baseUrlController.text = result.apiUrl;
        _apiKeyController.text = result.apiKey;
        _tenantIdController.text = result.tenantId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Credenciales QR cargadas con éxito. Conectando...'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );

      // Conexión automática instantánea
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.saveAndVerifyCredentials(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      tenantId: _tenantIdController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Conexión establecida exitosamente con el Tenant!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al conectar con el servidor'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.domain_verification_rounded,
                          size: 44,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Conexión Multi-Tenant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Escanea tu tarjeta de autorización o ingresa tus credenciales SaaS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BOTÓN DESTACADO: Escanear Tarjeta QR
                    OutlinedButton.icon(
                      onPressed: _scanQrCode,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Escanear Tarjeta de Acceso QR',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFF2563EB).withOpacity(0.06),
                      ),
                    ),
                    if (!_showManualEntry) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showManualEntry = true;
                          });
                        },
                        icon: const Icon(Icons.login_rounded, size: 20, color: Color(0xFF2563EB)),
                        label: const Text(
                          'Ingresa tus credenciales para conexión',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: const Color(0xFF2563EB).withOpacity(0.35),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Credenciales de Conexión',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  tooltip: 'Cerrar ingreso manual',
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _showManualEntry = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Base URL
                            Text(
                              'Servidor Central (Base URL)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _baseUrlController,
                              decoration: const InputDecoration(
                                hintText: 'https://api.metasociedad.com/wp-json/msinm/v1',
                                prefixIcon: Icon(Icons.link_rounded, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Ingresa la URL del servidor';
                                }
                                if (!val.startsWith('http')) {
                                  return 'La URL debe iniciar con https:// o http://';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tenant ID
                            Text(
                              'Tenant ID (x-tenant-id)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _tenantIdController,
                              decoration: const InputDecoration(
                                hintText: 'ej: MS-001',
                                prefixIcon: Icon(Icons.business_rounded, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'El Tenant ID es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // API Key
                            Text(
                              'API Key Secreta (x-api-key)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _apiKeyController,
                              obscureText: _obscureApiKey,
                              decoration: InputDecoration(
                                hintText: 'Ingresa tu x-api-key',
                                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureApiKey = !_obscureApiKey;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'El API Key es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Botón Conectar
                            ElevatedButton(
                              onPressed: auth.isTestingConnection ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: auth.isTestingConnection
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Validar y Conectar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
