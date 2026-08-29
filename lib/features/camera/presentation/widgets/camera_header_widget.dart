import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraHeaderWidget extends StatelessWidget {
  final FlashMode flashMode;
  final VoidCallback onToggleFlash;
  final VoidCallback onOpenUploadManager;
  final VoidCallback? onCloseApp;

  const CameraHeaderWidget({
    super.key,
    required this.flashMode,
    required this.onToggleFlash,
    required this.onOpenUploadManager,
    this.onCloseApp,
  });

  IconData get _flashIcon {
    switch (flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.3),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: onCloseApp ?? () {},
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_flashIcon, color: flashMode != FlashMode.off ? Colors.amber : Colors.white, size: 24),
                  onPressed: onToggleFlash,
                ),
                const SizedBox(width: 12),
                const Text(
                  'SNAPSYNC',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 28),
              onPressed: onOpenUploadManager,
            ),
          ],
        ),
      ),
    );
  }
}
