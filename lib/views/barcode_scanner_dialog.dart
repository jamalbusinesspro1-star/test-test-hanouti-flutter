import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/theme.dart';

class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController controller = MobileScannerController();
  bool _isDetected = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 380,
          child: Column(
            children: [
              AppBar(
                title: const Text('سكانير الباركود', style: TextStyle(fontSize: 16)),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.flash_on),
                    onPressed: () => controller.toggleTorch(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (_isDetected) return;
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _isDetected = true;
                        Navigator.pop(context, barcode.rawValue);
                        break;
                      }
                    }
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'وجّه الكاميرا نحو باركود السلعة ليتم مسحه تلقائياً',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
