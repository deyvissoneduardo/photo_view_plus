import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:photo_view_plus/src/domain/models/models.dart';

double getScaleForScaleState(
  PhotoViewScaleState scaleState,
  ScaleBoundaries scaleBoundaries,
) {
  switch (scaleState) {
    case PhotoViewScaleState.initial:
    case PhotoViewScaleState.zoomedIn:
    case PhotoViewScaleState.zoomedOut:
      return _clampSize(scaleBoundaries.initialScale, scaleBoundaries);
    case PhotoViewScaleState.covering:
      return _clampSize(
        _scaleForCovering(scaleBoundaries.outerSize, scaleBoundaries.childSize),
        scaleBoundaries,
      );
    case PhotoViewScaleState.originalSize:
      return _clampSize(1.0, scaleBoundaries);
  }
}

class ScaleBoundaries {
  const ScaleBoundaries(
    this._minScale,
    this._maxScale,
    this._initialScale,
    this.outerSize,
    this.childSize,
  );

  final PhotoViewScale _minScale;
  final PhotoViewScale _maxScale;
  final PhotoViewScale _initialScale;
  final Size outerSize;
  final Size childSize;

  double get minScale {
    final double resolved = _minScale.resolve(outerSize, childSize);
    assert(resolved >= 0.0);
    return resolved;
  }

  double get maxScale {
    return _maxScale
        .resolve(outerSize, childSize)
        .clamp(minScale, double.infinity);
  }

  double get initialScale {
    return _initialScale
        .resolve(outerSize, childSize)
        .clamp(minScale, maxScale);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleBoundaries &&
          runtimeType == other.runtimeType &&
          _minScale == other._minScale &&
          _maxScale == other._maxScale &&
          _initialScale == other._initialScale &&
          outerSize == other.outerSize &&
          childSize == other.childSize;

  @override
  int get hashCode =>
      _minScale.hashCode ^
      _maxScale.hashCode ^
      _initialScale.hashCode ^
      outerSize.hashCode ^
      childSize.hashCode;
}

double _scaleForCovering(Size size, Size childSize) {
  final double imageWidth = childSize.width;
  final double imageHeight = childSize.height;

  final double screenWidth = size.width;
  final double screenHeight = size.height;

  return math.max(screenWidth / imageWidth, screenHeight / imageHeight);
}

double _clampSize(double size, ScaleBoundaries scaleBoundaries) {
  return size.clamp(scaleBoundaries.minScale, scaleBoundaries.maxScale);
}

class CornersRange {
  const CornersRange(this.min, this.max);
  final double min;
  final double max;
}
