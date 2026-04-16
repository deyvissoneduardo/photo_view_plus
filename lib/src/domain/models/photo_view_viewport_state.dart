import 'package:flutter/widgets.dart';

@immutable
class PhotoViewViewportState {
  const PhotoViewViewportState({
    required this.position,
    required this.scale,
    required this.rotation,
    this.rotationFocusPoint,
  });

  final Offset position;
  final double scale;
  final double rotation;
  final Offset? rotationFocusPoint;

  PhotoViewViewportState copyWith({
    Offset? position,
    double? scale,
    double? rotation,
    Offset? rotationFocusPoint,
  }) {
    return PhotoViewViewportState(
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      rotationFocusPoint: rotationFocusPoint ?? this.rotationFocusPoint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoViewViewportState &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          scale == other.scale &&
          rotation == other.rotation &&
          rotationFocusPoint == other.rotationFocusPoint;

  @override
  int get hashCode =>
      position.hashCode ^
      scale.hashCode ^
      rotation.hashCode ^
      rotationFocusPoint.hashCode;
}
