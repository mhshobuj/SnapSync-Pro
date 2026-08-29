import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/models/captured_item.dart';

class CameraState extends Equatable {
  final bool isInitialized;
  final bool isInitializing;
  final CameraController? controller;
  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final List<double> presetZooms;
  final Offset? focusPoint;
  final bool showFocusRing;
  final List<CapturedItem> activeBatchItems;
  final bool isCapturing;
  final String? errorMessage;
  final FlashMode flashMode;

  final bool isPermissionDenied;
  final bool isPermanentlyDenied;

  const CameraState({
    this.isInitialized = false,
    this.isInitializing = false,
    this.controller,
    this.minZoom = 1.0,
    this.maxZoom = 5.0,
    this.currentZoom = 1.0,
    this.presetZooms = const [0.5, 1.0, 2.0],
    this.focusPoint,
    this.showFocusRing = false,
    this.activeBatchItems = const [],
    this.isCapturing = false,
    this.errorMessage,
    this.flashMode = FlashMode.off,
    this.isPermissionDenied = false,
    this.isPermanentlyDenied = false,
  });

  CameraState copyWith({
    bool? isInitialized,
    bool? isInitializing,
    CameraController? controller,
    double? minZoom,
    double? maxZoom,
    double? currentZoom,
    List<double>? presetZooms,
    Offset? focusPoint,
    bool? showFocusRing,
    List<CapturedItem>? activeBatchItems,
    bool? isCapturing,
    String? errorMessage,
    FlashMode? flashMode,
    bool? isPermissionDenied,
    bool? isPermanentlyDenied,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isInitializing: isInitializing ?? this.isInitializing,
      controller: controller ?? this.controller,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      currentZoom: currentZoom ?? this.currentZoom,
      presetZooms: presetZooms ?? this.presetZooms,
      focusPoint: focusPoint ?? this.focusPoint,
      showFocusRing: showFocusRing ?? this.showFocusRing,
      activeBatchItems: activeBatchItems ?? this.activeBatchItems,
      isCapturing: isCapturing ?? this.isCapturing,
      errorMessage: errorMessage,
      flashMode: flashMode ?? this.flashMode,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        isInitializing,
        controller,
        minZoom,
        maxZoom,
        currentZoom,
        presetZooms,
        focusPoint,
        showFocusRing,
        activeBatchItems,
        isCapturing,
        errorMessage,
        flashMode,
        isPermissionDenied,
        isPermanentlyDenied,
      ];
}
