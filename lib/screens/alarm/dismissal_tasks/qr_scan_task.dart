import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../theme/app_theme.dart';
import 'task_base.dart';

/// Task 4: QR Code / Barcode Scan. The user pre-registers a code (e.g.
/// stuck to the bathroom mirror or a kitchen item) when creating the
/// alarm; here we open the live camera scanner and only call
/// [onCompleted] when a decoded code's raw value exactly matches
/// [expectedPayload]. Any other code shows a "wrong code" hint and keeps
/// scanning — it does not dismiss the alarm.
class QrScanTask extends StatefulWidget {
  final String expectedPayload;
  final TaskCompletedCallback onCompleted;

  const QrScanTask({
    super.key,
    required this.expectedPayload,
    required this.onCompleted,
  });

  @override
  State<QrScanTask> createState() => _QrScanTaskState();
}

class _QrScanTaskState extends State<QrScanTask> {
  final MobileScannerController _controller = MobileScannerController();
  bool _wrongCodeFlash = false;
  bool _handledSuccess = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handledSuccess) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      if (value == widget.expectedPayload) {
        _handledSuccess = true;
        widget.onCompleted();
        return;
      } else {
        setState(() => _wrongCodeFlash = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _wrongCodeFlash = false);
        });
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
    return TaskScaffold(
      emoji: '🔳',
      title: 'Scan Code to Dismiss',
      instructions: 'Find the QR code you placed elsewhere and scan it',
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _wrongCodeFlash ? AppColors.danger : Colors.white54,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_wrongCodeFlash)
            const Text('Wrong code — keep looking', style: TextStyle(color: Colors.orangeAccent))
          else
            const Text('Point your camera at the registered code', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
