import 'dart:math' as math;
import 'dart:ui' show Size;

/// Describes how a scale should be resolved for a given viewport and child.
abstract class PhotoViewScale {
  const PhotoViewScale();

  const factory PhotoViewScale.fixed(double value) = PhotoViewFixedScale;

  static const PhotoViewScale contained = PhotoViewComputedScale.contained;
  static const PhotoViewScale covered = PhotoViewComputedScale.covered;

  double resolve(Size outerSize, Size childSize);
}

/// A fixed scale factor independent of the viewport size.
class PhotoViewFixedScale extends PhotoViewScale {
  const PhotoViewFixedScale(this.value);

  final double value;

  @override
  double resolve(Size outerSize, Size childSize) => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoViewFixedScale &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A scale resolved relative to the viewport.
///
/// ```
/// PhotoViewComputedScale.contained * 2
/// ```
class PhotoViewComputedScale extends PhotoViewScale {
  const PhotoViewComputedScale._internal(this._value, [this.multiplier = 1.0]);

  final _PhotoViewComputedScaleType _value;
  final double multiplier;

  static const contained =
      PhotoViewComputedScale._internal(_PhotoViewComputedScaleType.contained);
  static const covered =
      PhotoViewComputedScale._internal(_PhotoViewComputedScaleType.covered);
  static const containedNoScaleUp = PhotoViewComputedScale._internal(
    _PhotoViewComputedScaleType.containedNoScaleUp,
  );

  PhotoViewComputedScale operator *(double nextMultiplier) {
    return PhotoViewComputedScale._internal(_value, nextMultiplier);
  }

  PhotoViewComputedScale operator /(double divider) {
    return PhotoViewComputedScale._internal(_value, 1 / divider);
  }

  @override
  double resolve(Size outerSize, Size childSize) {
    final double baseScale = switch (_value) {
      _PhotoViewComputedScaleType.contained =>
        _scaleForContained(outerSize, childSize),
      _PhotoViewComputedScaleType.covered =>
        _scaleForCovered(outerSize, childSize),
      _PhotoViewComputedScaleType.containedNoScaleUp =>
        _scaleForContainedNoScaleUp(outerSize, childSize),
    };

    return baseScale * multiplier;
  }

  @override
  String toString() =>
      'PhotoViewComputedScale($_value, multiplier: $multiplier)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoViewComputedScale &&
          runtimeType == other.runtimeType &&
          _value == other._value &&
          multiplier == other.multiplier;

  @override
  int get hashCode => Object.hash(_value, multiplier);
}

enum _PhotoViewComputedScaleType {
  contained,
  covered,
  containedNoScaleUp,
}

double _scaleForContained(Size size, Size childSize) {
  return math.min(size.width / childSize.width, size.height / childSize.height);
}

double _scaleForCovered(Size size, Size childSize) {
  return math.max(size.width / childSize.width, size.height / childSize.height);
}

double _scaleForContainedNoScaleUp(Size size, Size childSize) {
  return math.min(1.0, _scaleForContained(size, childSize));
}
