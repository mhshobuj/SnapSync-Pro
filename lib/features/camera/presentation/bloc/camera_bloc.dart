import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/captured_item.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  Timer? _focusRingTimer;

  CameraBloc() : super(const CameraState()) {
    on<InitializeCameraEvent>(_onInitialize);
    on<SetZoomLevelEvent>(_onSetZoomLevel);
    on<PinchZoomEvent>(_onPinchZoom);
    on<SetFocusPointEvent>(_onSetFocusPoint);
    on<ClearFocusEvent>(_onClearFocus);
    on<CapturePhotoEvent>(_onCapturePhoto);
    on<ToggleCameraLensEvent>(_onToggleCameraLens);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<ClearActiveBatchEvent>(_onClearActiveBatch);
  }

  Future<void> _onInitialize(
    InitializeCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    emit(state.copyWith(isInitializing: true, errorMessage: null));
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        emit(state.copyWith(
          isInitializing: false,
          errorMessage: 'No hardware cameras found on this device.',
        ));
        return;
      }

      await _initSelectedCamera(emit);
    } catch (e) {
      emit(state.copyWith(
        isInitializing: false,
        errorMessage: 'Failed to initialize camera: ${e.toString()}',
      ));
    }
  }

  Future<void> _initSelectedCamera(Emitter<CameraState> emit) async {
    final camera = _cameras[_selectedCameraIndex];
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    double minZoom = 1.0;
    double maxZoom = 5.0;

    try {
      minZoom = await controller.getMinZoomLevel();
      maxZoom = await controller.getMaxZoomLevel();
    } catch (_) {}

    // Determine available preset zoom pills
    final presets = <double>[];
    if (minZoom < 1.0) presets.add(0.5);
    presets.add(1.0);
    if (maxZoom >= 2.0) presets.add(2.0);
    if (maxZoom >= 5.0) presets.add(5.0);

    emit(state.copyWith(
      isInitialized: true,
      isInitializing: false,
      controller: controller,
      minZoom: minZoom,
      maxZoom: maxZoom,
      currentZoom: 1.0,
      presetZooms: presets,
    ));
  }

  Future<void> _onSetZoomLevel(
    SetZoomLevelEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (!state.isInitialized || state.controller == null) return;
    final targetZoom = event.zoom.clamp(state.minZoom, state.maxZoom);
    try {
      await state.controller!.setZoomLevel(targetZoom);
      emit(state.copyWith(currentZoom: targetZoom));
    } catch (_) {}
  }

  Future<void> _onPinchZoom(
    PinchZoomEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (!state.isInitialized || state.controller == null) return;
    final newZoom = (state.currentZoom * event.scaleDelta).clamp(state.minZoom, state.maxZoom);
    try {
      await state.controller!.setZoomLevel(newZoom);
      emit(state.copyWith(currentZoom: newZoom));
    } catch (_) {}
  }

  Future<void> _onSetFocusPoint(
    SetFocusPointEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (!state.isInitialized || state.controller == null) return;

    final double x = event.tapPosition.dx / event.previewSize.width;
    final double y = event.tapPosition.dy / event.previewSize.height;

    final Offset normalizedPoint = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

    try {
      await state.controller!.setFocusPoint(normalizedPoint);
      await state.controller!.setExposurePoint(normalizedPoint);
    } catch (_) {}

    _focusRingTimer?.cancel();
    emit(state.copyWith(
      focusPoint: event.tapPosition,
      showFocusRing: true,
    ));

    _focusRingTimer = Timer(const Duration(seconds: 2), () {
      add(ClearFocusEvent());
    });
  }

  void _onClearFocus(ClearFocusEvent event, Emitter<CameraState> emit) {
    emit(state.copyWith(showFocusRing: false));
  }

  Future<void> _onCapturePhoto(
    CapturePhotoEvent event,
    Emitter<CameraState> emit,
  ) async {
    emit(state.copyWith(isCapturing: true));

    try {
      String filePath = '';
      int fileSize = 0;

      if (state.isInitialized && state.controller != null) {
        final XFile file = await state.controller!.takePicture();
        filePath = file.path;
        fileSize = await file.length();
      } else {
        // Fallback for emulator / mock camera preview
        final tempDir = await getTemporaryDirectory();
        final mockFile = File('${tempDir.path}/mock_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await mockFile.writeAsBytes(List.generate(1024 * 150, (i) => i % 256));
        filePath = mockFile.path;
        fileSize = await mockFile.length();
      }

      final newItem = CapturedItem(
        id: const Uuid().v4(),
        filePath: filePath,
        fileName: 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileSizeBytes: fileSize,
        timestamp: DateTime.now(),
      );

      final updatedList = List<CapturedItem>.from(state.activeBatchItems)..add(newItem);

      emit(state.copyWith(
        isCapturing: false,
        activeBatchItems: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCapturing: false,
        errorMessage: 'Capture failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onToggleCameraLens(
    ToggleCameraLensEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameras.length <= 1) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await state.controller?.dispose();
    await _initSelectedCamera(emit);
  }

  Future<void> _onToggleFlash(
    ToggleFlashEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (!state.isInitialized || state.controller == null) return;
    FlashMode nextMode;
    switch (state.flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.torch;
        break;
      default:
        nextMode = FlashMode.off;
        break;
    }
    try {
      await state.controller!.setFlashMode(nextMode);
      emit(state.copyWith(flashMode: nextMode));
    } catch (_) {}
  }

  void _onClearActiveBatch(
    ClearActiveBatchEvent event,
    Emitter<CameraState> emit,
  ) {
    emit(state.copyWith(activeBatchItems: []));
  }

  @override
  Future<void> close() {
    _focusRingTimer?.cancel();
    state.controller?.dispose();
    return super.close();
  }
}
