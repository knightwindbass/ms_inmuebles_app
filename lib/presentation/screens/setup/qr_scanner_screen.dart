import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Resultado del escaneo de la tarjeta de autorización QR
class QrCredentialsResult {
  final String apiUrl;
  final String apiKey;
  final String tenantId;

  static const String delimiter = r'-$-';

  QrCredentialsResult({
    required this.apiUrl,
    required this.apiKey,
    required this.tenantId,
  });

  /// Parsea la cadena con el formato:
  /// URL -$- API_KEY -$- TENANT_ID
  static QrCredentialsResult? parse(String rawText) {
    final text = rawText.trim();
    if (text.contains(delimiter)) {
      final parts = text.split(delimiter).map((p) => p.trim()).toList();
      if (parts.length >= 3) {
        String url = parts[0];
        // Asegurar que la URL sea válida
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        return QrCredentialsResult(
          apiUrl: url,
          apiKey: parts[1],
          tenantId: parts[2],
        );
      }
    }
    return null;
  }
}

/// Pantalla moderna para escanear el código QR de acceso / tarjeta de autorización
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final credentials = QrCredentialsResult.parse(rawValue);
        if (credentials != null) {
          _isProcessing = true;
          _controller.stop();
          Navigator.of(context).pop(credentials);
          break;
        } else {
          // Mostrar mensaje sutil de formato incorrecto
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(r'El código QR no tiene el formato de autorización requerido (-$-)'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Escanear Tarjeta de Acceso',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: Colors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Visor de Cámara
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay Visual con Marco de Escaneo
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2563EB), width: 3),
              ),
            ),
          ),

          // Instrucción Inferior
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8), size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Apunta la cámara al código QR facilitado',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Los datos de API, Tenant y Servidor se configurarán automáticamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
