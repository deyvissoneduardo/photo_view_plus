import 'package:flutter/widgets.dart';
import 'package:photo_view/src/domain/use_cases/photo_view_transformations.dart';

/// Pure layout metrics used by gesture and transform code.
@immutable
class PhotoViewLayoutMetrics {
  const PhotoViewLayoutMetrics({
    required this.scaleBoundaries,
    required this.position,
    required this.scale,
    required this.basePosition,
  });

  final ScaleBoundaries scaleBoundaries;
  final Offset position;
  final double scale;
  final Alignment basePosition;

  CornersRange cornersX() {
    final double computedWidth = scaleBoundaries.childSize.width * scale;
    final double widthDiff = computedWidth - scaleBoundaries.outerSize.width;
    final double minX = ((basePosition.x - 1).abs() / 2) * widthDiff * -1;
    final double maxX = ((basePosition.x + 1).abs() / 2) * widthDiff;
    return CornersRange(minX, maxX);
  }

  CornersRange cornersY() {
    final double computedHeight = scaleBoundaries.childSize.height * scale;
    final double heightDiff = computedHeight - scaleBoundaries.outerSize.height;
    final double minY = ((basePosition.y - 1).abs() / 2) * heightDiff * -1;
    final double maxY = ((basePosition.y + 1).abs() / 2) * heightDiff;
    return CornersRange(minY, maxY);
  }

  Offset clampPosition([Offset? nextPosition]) {
    final Offset resolvedPosition = nextPosition ?? position;
    final double computedWidth = scaleBoundaries.childSize.width * scale;
    final double computedHeight = scaleBoundaries.childSize.height * scale;

    double finalX = 0.0;
    if (scaleBoundaries.outerSize.width < computedWidth) {
      final CornersRange horizontal = cornersX();
      finalX = resolvedPosition.dx.clamp(horizontal.min, horizontal.max);
    }

    double finalY = 0.0;
    if (scaleBoundaries.outerSize.height < computedHeight) {
      final CornersRange vertical = cornersY();
      finalY = resolvedPosition.dy.clamp(vertical.min, vertical.max);
    }

    return Offset(finalX, finalY);
  }

  bool shouldMove(Offset move, Axis mainAxis) {
    if (mainAxis == Axis.vertical) {
      return _shouldMoveAxis(_hitCornersY(), move.dy);
    }
    return _shouldMoveAxis(_hitCornersX(), move.dx);
  }

  _HitCorners _hitCornersX() {
    final double childWidth = scaleBoundaries.childSize.width * scale;
    if (scaleBoundaries.outerSize.width >= childWidth) {
      return const _HitCorners(true, true);
    }

    final CornersRange horizontal = cornersX();
    final double translatedX = -position.dx;
    return _HitCorners(
      translatedX <= horizontal.min,
      translatedX >= horizontal.max,
    );
  }

  _HitCorners _hitCornersY() {
    final double childHeight = scaleBoundaries.childSize.height * scale;
    if (scaleBoundaries.outerSize.height >= childHeight) {
      return const _HitCorners(true, true);
    }

    final CornersRange vertical = cornersY();
    final double translatedY = -position.dy;
    return _HitCorners(
      translatedY <= vertical.min,
      translatedY >= vertical.max,
    );
  }

  bool _shouldMoveAxis(_HitCorners hitCorners, double mainAxisMove) {
    if (mainAxisMove == 0) {
      return false;
    }

    if (!hitCorners.hasHitAny) {
      return true;
    }

    final bool axisBlocked = hitCorners.hasHitBoth ||
        (hitCorners.hasHitMax ? mainAxisMove > 0 : mainAxisMove < 0);
    return !axisBlocked;
  }
}

class _HitCorners {
  const _HitCorners(this.hasHitMin, this.hasHitMax);

  final bool hasHitMin;
  final bool hasHitMax;

  bool get hasHitAny => hasHitMin || hasHitMax;

  bool get hasHitBoth => hasHitMin && hasHitMax;
}
