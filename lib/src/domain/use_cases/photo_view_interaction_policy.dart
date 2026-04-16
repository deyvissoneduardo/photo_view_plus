import 'package:flutter/widgets.dart';
import 'package:photo_view/src/core/photo_view_layout.dart';
import 'package:photo_view/src/domain/models/photo_view_viewport_state.dart';
import 'package:photo_view/src/domain/use_cases/photo_view_transformations.dart';
import 'package:photo_view/src/photo_view_scale_state.dart';

typedef PhotoViewClampPositionPolicy = Offset Function(
  PhotoViewLayoutMetrics metrics,
  Offset nextPosition,
);

typedef PhotoViewGestureEndPolicy = PhotoViewGestureEndResult Function(
  PhotoViewGestureEndContext context,
);

typedef PhotoViewFilterQualityProvider = FilterQuality Function(
  PhotoViewFilterQualityContext context,
);

@immutable
class PhotoViewGestureEndContext {
  const PhotoViewGestureEndContext({
    required this.viewportState,
    required this.layoutMetrics,
    required this.scaleBoundaries,
    required this.scaleBefore,
    required this.velocity,
  });

  final PhotoViewViewportState viewportState;
  final PhotoViewLayoutMetrics layoutMetrics;
  final ScaleBoundaries scaleBoundaries;
  final double scaleBefore;
  final Velocity velocity;
}

@immutable
class PhotoViewGestureEndResult {
  const PhotoViewGestureEndResult({
    this.targetScale,
    this.targetPosition,
  });

  final double? targetScale;
  final Offset? targetPosition;

  bool get hasScaleAnimation => targetScale != null;
  bool get hasPositionAnimation => targetPosition != null;
}

@immutable
class PhotoViewFilterQualityContext {
  const PhotoViewFilterQualityContext({
    required this.viewportState,
    required this.scaleState,
    required this.preferredQuality,
    required this.isGestureActive,
  });

  final PhotoViewViewportState viewportState;
  final PhotoViewScaleState scaleState;
  final FilterQuality preferredQuality;
  final bool isGestureActive;
}

Offset defaultClampPositionPolicy(
  PhotoViewLayoutMetrics metrics,
  Offset nextPosition,
) {
  return metrics.clampPosition(nextPosition);
}

PhotoViewGestureEndResult defaultGestureEndPolicy(
  PhotoViewGestureEndContext context,
) {
  final currentScale = context.viewportState.scale;
  final currentPosition = context.viewportState.position;
  final maxScale = context.scaleBoundaries.maxScale;
  final minScale = context.scaleBoundaries.minScale;

  if (currentScale > maxScale) {
    final scaleComebackRatio = maxScale / currentScale;
    return PhotoViewGestureEndResult(
      targetScale: maxScale,
      targetPosition: context.layoutMetrics.clampPosition(
        currentPosition * scaleComebackRatio,
      ),
    );
  }

  if (currentScale < minScale) {
    final scaleComebackRatio = minScale / currentScale;
    return PhotoViewGestureEndResult(
      targetScale: minScale,
      targetPosition: context.layoutMetrics.clampPosition(
        currentPosition * scaleComebackRatio,
      ),
    );
  }

  final magnitude = context.velocity.pixelsPerSecond.distance;
  if (context.scaleBefore / currentScale == 1.0 && magnitude >= 400.0) {
    final direction = context.velocity.pixelsPerSecond / magnitude;
    return PhotoViewGestureEndResult(
      targetPosition: context.layoutMetrics.clampPosition(
        currentPosition + direction * 100.0,
      ),
    );
  }

  final clampedPosition = context.layoutMetrics.clampPosition(currentPosition);
  if (clampedPosition != currentPosition) {
    return PhotoViewGestureEndResult(targetPosition: clampedPosition);
  }

  return const PhotoViewGestureEndResult();
}

FilterQuality defaultFilterQualityProvider(
  PhotoViewFilterQualityContext context,
) {
  if (!context.isGestureActive) {
    return context.preferredQuality;
  }

  switch (context.preferredQuality) {
    case FilterQuality.high:
      return FilterQuality.medium;
    case FilterQuality.medium:
      return FilterQuality.low;
    case FilterQuality.low:
    case FilterQuality.none:
      return context.preferredQuality;
  }
}

@immutable
class PhotoViewInteractionPolicy {
  const PhotoViewInteractionPolicy({
    this.clampPosition = defaultClampPositionPolicy,
    this.onGestureEnd = defaultGestureEndPolicy,
    this.filterQuality = defaultFilterQualityProvider,
  });

  final PhotoViewClampPositionPolicy clampPosition;
  final PhotoViewGestureEndPolicy onGestureEnd;
  final PhotoViewFilterQualityProvider filterQuality;
}
