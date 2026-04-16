import 'package:flutter/widgets.dart';
import 'package:photo_view/src/domain/models/photo_view_viewport_state.dart';
import 'package:photo_view/src/domain/use_cases/photo_view_interaction_policy.dart';
import 'package:photo_view/src/photo_view_scale_state.dart';

typedef PhotoViewOverlayBuilder = Widget? Function(
  BuildContext context,
  PhotoViewOverlayDetails details,
);

typedef PhotoViewBackgroundBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

typedef PhotoViewLoadingStateBuilder = Widget Function(
  BuildContext context,
  PhotoViewLoadingDetails details,
);

typedef PhotoViewErrorStateBuilder = Widget Function(
  BuildContext context,
  PhotoViewErrorDetails details,
);

@immutable
class PhotoViewOverlayDetails {
  const PhotoViewOverlayDetails({
    required this.viewportState,
    required this.scaleState,
    required this.outerSize,
    this.imageProvider,
    this.isLoading = false,
    this.error,
    this.stackTrace,
  });

  final PhotoViewViewportState? viewportState;
  final PhotoViewScaleState scaleState;
  final Size outerSize;
  final ImageProvider? imageProvider;
  final bool isLoading;
  final Object? error;
  final StackTrace? stackTrace;
}

@immutable
class PhotoViewLoadingDetails {
  const PhotoViewLoadingDetails({
    required this.imageProvider,
    required this.outerSize,
    this.progress,
  });

  final ImageProvider imageProvider;
  final Size outerSize;
  final ImageChunkEvent? progress;
}

@immutable
class PhotoViewErrorDetails {
  const PhotoViewErrorDetails({
    required this.imageProvider,
    required this.outerSize,
    required this.error,
    this.stackTrace,
  });

  final ImageProvider imageProvider;
  final Size outerSize;
  final Object error;
  final StackTrace? stackTrace;
}

@immutable
class PhotoViewOptions {
  const PhotoViewOptions({
    this.backgroundDecoration,
    this.wantKeepAlive,
    this.customSize,
    this.gestureDetectorBehavior,
    this.tightMode,
    this.filterQuality,
    this.disableGestures,
    this.enablePanAlways,
    this.strictScale,
    this.interactionPolicy,
    this.overlayBuilder,
    this.backgroundBuilder,
    this.loadingStateBuilder,
    this.errorStateBuilder,
  });

  final BoxDecoration? backgroundDecoration;
  final bool? wantKeepAlive;
  final Size? customSize;
  final HitTestBehavior? gestureDetectorBehavior;
  final bool? tightMode;
  final FilterQuality? filterQuality;
  final bool? disableGestures;
  final bool? enablePanAlways;
  final bool? strictScale;
  final PhotoViewInteractionPolicy? interactionPolicy;
  final PhotoViewOverlayBuilder? overlayBuilder;
  final PhotoViewBackgroundBuilder? backgroundBuilder;
  final PhotoViewLoadingStateBuilder? loadingStateBuilder;
  final PhotoViewErrorStateBuilder? errorStateBuilder;

  PhotoViewOptions copyWith({
    BoxDecoration? backgroundDecoration,
    bool? wantKeepAlive,
    Size? customSize,
    HitTestBehavior? gestureDetectorBehavior,
    bool? tightMode,
    FilterQuality? filterQuality,
    bool? disableGestures,
    bool? enablePanAlways,
    bool? strictScale,
    PhotoViewInteractionPolicy? interactionPolicy,
    PhotoViewOverlayBuilder? overlayBuilder,
    PhotoViewBackgroundBuilder? backgroundBuilder,
    PhotoViewLoadingStateBuilder? loadingStateBuilder,
    PhotoViewErrorStateBuilder? errorStateBuilder,
  }) {
    return PhotoViewOptions(
      backgroundDecoration: backgroundDecoration ?? this.backgroundDecoration,
      wantKeepAlive: wantKeepAlive ?? this.wantKeepAlive,
      customSize: customSize ?? this.customSize,
      gestureDetectorBehavior:
          gestureDetectorBehavior ?? this.gestureDetectorBehavior,
      tightMode: tightMode ?? this.tightMode,
      filterQuality: filterQuality ?? this.filterQuality,
      disableGestures: disableGestures ?? this.disableGestures,
      enablePanAlways: enablePanAlways ?? this.enablePanAlways,
      strictScale: strictScale ?? this.strictScale,
      interactionPolicy: interactionPolicy ?? this.interactionPolicy,
      overlayBuilder: overlayBuilder ?? this.overlayBuilder,
      backgroundBuilder: backgroundBuilder ?? this.backgroundBuilder,
      loadingStateBuilder: loadingStateBuilder ?? this.loadingStateBuilder,
      errorStateBuilder: errorStateBuilder ?? this.errorStateBuilder,
    );
  }
}

enum PhotoViewGalleryPageRetentionPolicy {
  reset,
  keepAlive,
}

@immutable
class PhotoViewGalleryOptions {
  const PhotoViewGalleryOptions({
    this.scrollPhysics,
    this.scrollDirection,
    this.allowImplicitScrolling,
    this.pageSnapping,
    this.preloadPagesCount,
    this.pageRetentionPolicy,
    this.options,
  });

  final ScrollPhysics? scrollPhysics;
  final Axis? scrollDirection;
  final bool? allowImplicitScrolling;
  final bool? pageSnapping;
  final int? preloadPagesCount;
  final PhotoViewGalleryPageRetentionPolicy? pageRetentionPolicy;
  final PhotoViewOptions? options;
}
