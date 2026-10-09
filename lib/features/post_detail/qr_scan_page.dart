import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../shared/widgets/widgets.dart';

/// Lê o QR de check-in (`saveeasy:checkin:<post>:<código>`) e devolve o código.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue ?? '';
      final code = value.startsWith('saveeasy:checkin:') ? value.split(':').last : value;
      if (RegExp(r'^[A-Fa-f0-9]{6}$').hasMatch(code)) {
        _done = true;
        Navigator.pop(context, code.toUpperCase());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: const AppBackButton(color: Colors.white),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ler QR de check-in', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: _onDetect,
            errorBuilder: (context, error) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não foi possível abrir a câmera. Libere o acesso ou digite o código.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
