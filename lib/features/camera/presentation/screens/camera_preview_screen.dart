import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/camera_bloc.dart';
import '../bloc/camera_event.dart';
import '../bloc/camera_state.dart';
import '../widgets/camera_header_widget.dart';
import '../widgets/focus_ring_widget.dart';
import '../widgets/zoom_controls_widget.dart';
import 'package:snapsync_pro/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:snapsync_pro/features/sync/presentation/bloc/sync_event.dart';
import 'package:snapsync_pro/features/sync/presentation/screens/upload_manager_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    context.read<CameraBloc>().add(InitializeCameraEvent());
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to close the app?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop(true);
              await SystemNavigator.pop();
              exit(0);
            },
            child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  void _navigateToUploadManager(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UploadManagerScreen()),
    );
  }

  void _handleUploadBatch(BuildContext context, CameraState cameraState) {
    if (cameraState.activeBatchItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one image before uploading a batch.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Dispatch items to SyncBloc queue
    context.read<SyncBloc>().add(CreateBatchAndQueueEvent(cameraState.activeBatchItems));

    // Clear active camera batch
    context.read<CameraBloc>().add(ClearActiveBatchEvent());

    // Navigate to Upload Manager screen
    _navigateToUploadManager(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
      body: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, cameraState) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Viewport or Mock Fallback Viewport
              if (cameraState.isInitialized && cameraState.controller != null)
                GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = cameraState.currentZoom;
                  },
                  onScaleUpdate: (details) {
                    final newScale = _baseScale * details.scale;
                    final delta = newScale / cameraState.currentZoom;
                    context.read<CameraBloc>().add(PinchZoomEvent(delta));
                  },
                  onTapDown: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    context.read<CameraBloc>().add(SetFocusPointEvent(
                          tapPosition: details.localPosition,
                          previewSize: box.size,
                        ));
                  },
                  child: CameraPreview(cameraState.controller!),
                )
              else
                // Mock Camera Preview Background for Emulator or permission testing
                GestureDetector(
                  onTapDown: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    context.read<CameraBloc>().add(SetFocusPointEvent(
                          tapPosition: details.localPosition,
                          previewSize: box.size,
                        ));
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'LIVE VIEWPORT',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap screen to focus | Pinch to zoom',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 2. Animated Tap Focus Ring Overlay
              if (cameraState.showFocusRing && cameraState.focusPoint != null)
                FocusRingWidget(position: cameraState.focusPoint!),

              // 3. Header Bar Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CameraHeaderWidget(
                  flashMode: cameraState.flashMode,
                  onToggleFlash: () {
                    context.read<CameraBloc>().add(ToggleFlashEvent());
                  },
                  onOpenUploadManager: () => _navigateToUploadManager(context),
                  onCloseApp: () => _showExitConfirmationDialog(context),
                ),
              ),

              // 4. Zoom Slider & Preset Pills Overlay
              ZoomControlsWidget(
                currentZoom: cameraState.currentZoom,
                minZoom: cameraState.minZoom,
                maxZoom: cameraState.maxZoom,
                presetZooms: cameraState.presetZooms,
                onZoomChanged: (zoom) {
                  context.read<CameraBloc>().add(SetZoomLevelEvent(zoom));
                },
              ),

              // 5. Bottom Controls & Shutter Bar matching PDF design
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85), Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left Thumbnail / Count Badge
                          GestureDetector(
                            onTap: () => _navigateToUploadManager(context),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white54, width: 1.5),
                                color: Colors.white10,
                              ),
                              child: Stack(
                                children: [
                                  if (cameraState.activeBatchItems.isNotEmpty &&
                                      cameraState.activeBatchItems.last.filePath.isNotEmpty &&
                                      File(cameraState.activeBatchItems.last.filePath).existsSync())
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(cameraState.activeBatchItems.last.filePath),
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                      ),
                                    )
                                  else
                                    const Center(
                                      child: Icon(Icons.photo_library, color: Colors.white, size: 24),
                                    ),
                                  if (cameraState.activeBatchItems.isNotEmpty)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${cameraState.activeBatchItems.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Center Shutter Button
                          GestureDetector(
                            onTap: cameraState.isCapturing
                                ? null
                                : () {
                                    context.read<CameraBloc>().add(CapturePhotoEvent());
                                  },
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cameraState.isCapturing ? Colors.red : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Right Lens Switch Button
                          IconButton(
                            icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                            onPressed: () {
                              context.read<CameraBloc>().add(ToggleCameraLensEvent());
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Prominent "UPLOAD BATCH (N)" Action Button matching PDF UI
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                          label: Text(
                            'UPLOAD BATCH (${cameraState.activeBatchItems.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          onPressed: () => _handleUploadBatch(context, cameraState),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}
