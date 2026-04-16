import 'package:flutter/widgets.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/src/core/photo_view_layout.dart';
import 'package:photo_view/src/domain/use_cases/photo_view_interaction_policy.dart';
import 'package:photo_view/src/domain/use_cases/photo_view_transformations.dart';
import 'package:test/test.dart';

void main() {
  group('ScaleBoundaries', () {
    const outerSize = Size(400, 300);
    const childSize = Size(200, 100);

    test('resolves fixed and computed scales', () {
      const boundaries = ScaleBoundaries(
        PhotoViewScale.fixed(0.5),
        PhotoViewComputedScale.covered,
        PhotoViewComputedScale.contained,
        outerSize,
        childSize,
      );

      expect(boundaries.minScale, 0.5);
      expect(boundaries.maxScale, 3.0);
      expect(boundaries.initialScale, 2.0);
    });

    test('resolves containedNoScaleUp without stretching small content', () {
      const smallBoundaries = ScaleBoundaries(
        PhotoViewScale.fixed(0.1),
        PhotoViewScale.fixed(10.0),
        PhotoViewComputedScale.containedNoScaleUp,
        outerSize,
        childSize,
      );

      const largeBoundaries = ScaleBoundaries(
        PhotoViewScale.fixed(0.1),
        PhotoViewScale.fixed(10.0),
        PhotoViewComputedScale.containedNoScaleUp,
        Size(100, 100),
        Size(300, 300),
      );

      expect(smallBoundaries.initialScale, 1.0);
      expect(largeBoundaries.initialScale, closeTo(1 / 3, 0.0001));
    });

    test('clamps initial scale between min and max', () {
      const boundaries = ScaleBoundaries(
        PhotoViewScale.fixed(1.5),
        PhotoViewScale.fixed(2.0),
        PhotoViewScale.fixed(4.0),
        outerSize,
        childSize,
      );

      expect(boundaries.initialScale, 2.0);
    });
  });

  test('layout metrics clamp position using viewport bounds', () {
    const boundaries = ScaleBoundaries(
      PhotoViewScale.fixed(1.0),
      PhotoViewScale.fixed(4.0),
      PhotoViewScale.fixed(2.0),
      Size(100, 100),
      Size(100, 100),
    );

    const metrics = PhotoViewLayoutMetrics(
      scaleBoundaries: boundaries,
      position: Offset.zero,
      scale: 2.0,
      basePosition: Alignment.center,
    );

    expect(metrics.clampPosition(const Offset(80, -80)), const Offset(50, -50));
    expect(metrics.shouldMove(const Offset(10, 0), Axis.horizontal), isTrue);
  });

  test('layout metrics respect non-centered base position', () {
    const boundaries = ScaleBoundaries(
      PhotoViewScale.fixed(1.0),
      PhotoViewScale.fixed(4.0),
      PhotoViewScale.fixed(2.0),
      Size(100, 100),
      Size(100, 100),
    );

    const metrics = PhotoViewLayoutMetrics(
      scaleBoundaries: boundaries,
      position: Offset.zero,
      scale: 2.0,
      basePosition: Alignment.topLeft,
    );

    expect(metrics.cornersX().min, -100);
    expect(metrics.cornersX().max, 0);
    expect(metrics.cornersY().min, -100);
    expect(metrics.cornersY().max, 0);
    expect(
      metrics.clampPosition(const Offset(40, -120)),
      const Offset(0, -100),
    );
  });

  test('default gesture end policy clamps overscaled viewport', () {
    const boundaries = ScaleBoundaries(
      PhotoViewScale.fixed(1.0),
      PhotoViewScale.fixed(3.0),
      PhotoViewScale.fixed(1.0),
      Size(200, 200),
      Size(100, 100),
    );

    const metrics = PhotoViewLayoutMetrics(
      scaleBoundaries: boundaries,
      position: Offset(160, 20),
      scale: 4.0,
      basePosition: Alignment.center,
    );

    final result = defaultGestureEndPolicy(
      const PhotoViewGestureEndContext(
        viewportState: PhotoViewViewportState(
          position: Offset(160, 20),
          scale: 4.0,
          rotation: 0,
        ),
        layoutMetrics: metrics,
        scaleBoundaries: boundaries,
        scaleBefore: 1.0,
        velocity: Velocity(pixelsPerSecond: Offset.zero),
      ),
    );

    expect(result.targetScale, 3.0);
    expect(result.targetPosition, const Offset(100, 15));
  });

  test('default filter quality provider reduces quality during gestures', () {
    final quality = defaultFilterQualityProvider(
      const PhotoViewFilterQualityContext(
        viewportState: PhotoViewViewportState(
          position: Offset.zero,
          scale: 1.0,
          rotation: 0,
        ),
        scaleState: PhotoViewScaleState.zoomedIn,
        preferredQuality: FilterQuality.high,
        isGestureActive: true,
      ),
    );

    expect(quality, FilterQuality.medium);
  });
}
