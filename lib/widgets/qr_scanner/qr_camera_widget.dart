import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';

class QRCameraWidget extends StatefulWidget {
  final Function(String) onQRScanned;
  final bool isFlashOn;
  final VoidCallback onFlashToggle;

  const QRCameraWidget({
    super.key,
    required this.onQRScanned,
    required this.isFlashOn,
    required this.onFlashToggle,
  });

  @override
  State<QRCameraWidget> createState() => _QRCameraWidgetState();
}

class _QRCameraWidgetState extends State<QRCameraWidget>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeScanAnimation();
  }
  
  void _initializeScanAnimation() {
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    
    _scanLineController.repeat();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && scanData.code!.isNotEmpty) {
        widget.onQRScanned(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // QR Camera View
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: const Color(0xFF667eea),
                borderRadius: 20,
                borderLength: 40,
                borderWidth: 6,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
            
            // Animated Scan Line
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ScanLinePainter(_scanLineAnimation.value),
                  );
                },
              ),
            ),
            
            // Flash Button
            Positioned(
              top: 20,
              right: 20,
              child: _buildFlashButton(),
            ),
            
            // Scanning Instructions
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: _buildInstructions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: widget.onFlashToggle,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: widget.isFlashOn ? Colors.yellow : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Text(
        'Position QR code within the frame',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void pauseCamera() {
    controller?.pauseCamera();
  }

  void resumeCamera() {
    controller?.resumeCamera();
  }
}

class ScanLinePainter extends CustomPainter {
  final double animationValue;

  ScanLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667eea).withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        const Color(0xFF667eea).withValues(alpha: 0.8),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = gradient.createShader(rect);
    paint.shader = shader;

    final y = size.height * animationValue;
    canvas.drawLine(
      Offset(size.width * 0.15, y),
      Offset(size.width * 0.85, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
