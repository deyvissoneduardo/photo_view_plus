import 'package:flutter/widgets.dart';
import 'package:photo_view_plus/src/core/photo_view_layout.dart';
import 'package:photo_view_plus/src/domain/models/photo_view_viewport_state.dart';
import 'package:photo_view_plus/src/domain/use_cases/photo_view_interaction_policy.dart';
import 'package:photo_view_plus/src/domain/use_cases/photo_view_transformations.dart';

class PhotoViewReturnCoordinator {
  const PhotoViewReturnCoordinator();

  PhotoViewGestureEndResult resolve({
    required PhotoViewInteractionPolicy interactionPolicy,
    required PhotoViewViewportState viewportState,
    required PhotoViewLayoutMetrics layoutMetrics,
    required ScaleBoundaries scaleBoundaries,
    required double scaleBefore,
    required Velocity velocity,
  }) {
    return interactionPolicy.onGestureEnd(
      PhotoViewGestureEndContext(
        viewportState: viewportState,
        layoutMetrics: layoutMetrics,
        scaleBoundaries: scaleBoundaries,
        scaleBefore: scaleBefore,
        velocity: velocity,
      ),
    );
  }
}
