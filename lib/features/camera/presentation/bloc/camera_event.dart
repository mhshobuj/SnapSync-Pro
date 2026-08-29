import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCameraEvent extends CameraEvent {}

class SetZoomLevelEvent extends CameraEvent {
  final double zoom;
  const SetZoomLevelEvent(this.zoom);

  @override
  List<Object?> get props => [zoom];
}

class PinchZoomEvent extends CameraEvent {
  final double scaleDelta;
  const PinchZoomEvent(this.scaleDelta);

  @override
  List<Object?> get props => [scaleDelta];
}

class SetFocusPointEvent extends CameraEvent {
  final Offset tapPosition;
  final Size previewSize;

  const SetFocusPointEvent({
    required this.tapPosition,
    required this.previewSize,
  });

  @override
  List<Object?> get props => [tapPosition, previewSize];
}

class ClearFocusEvent extends CameraEvent {}

class CapturePhotoEvent extends CameraEvent {}

class ToggleCameraLensEvent extends CameraEvent {}

class ToggleFlashEvent extends CameraEvent {}

class ClearActiveBatchEvent extends CameraEvent {}
