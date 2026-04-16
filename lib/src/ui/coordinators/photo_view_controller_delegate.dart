import 'package:flutter/widgets.dart';
import 'package:photo_view/photo_view.dart'
    show
        PhotoViewControllerBase,
        PhotoViewScaleState,
        PhotoViewScaleStateController,
        ScaleStateCycle;
import 'package:photo_view/src/core/photo_view_core.dart';
import 'package:photo_view/src/domain/models/models.dart';
import 'package:photo_view/src/domain/use_cases/use_cases.dart';

mixin PhotoViewControllerDelegate on State<PhotoViewCore> {
  PhotoViewControllerBase get controller => widget.controller;

  PhotoViewScaleStateController get scaleStateController =>
      widget.scaleStateController;

  ScaleBoundaries get scaleBoundaries => widget.scaleBoundaries;

  ScaleStateCycle get scaleStateCycle => widget.scaleStateCycle;

  Alignment get basePosition => widget.basePosition;
  PhotoViewInteractionPolicy get interactionPolicy => widget.interactionPolicy;
  Function(double prevScale, double nextScale)? _animateScale;

  bool markNeedsScaleRecalc = true;

  void initDelegate() {
    controller.addIgnorableListener(_blindScaleListener);
    scaleStateController.addIgnorableListener(_blindScaleStateListener);
  }

  void _blindScaleStateListener() {
    if (!scaleStateController.hasChanged) {
      return;
    }
    if (_animateScale == null || scaleStateController.isZooming) {
      controller.setScaleInvisibly(scale);
      return;
    }
    final double prevScale = controller.scale ??
        getScaleForScaleState(
          scaleStateController.prevScaleState,
          scaleBoundaries,
        );

    final double nextScale = getScaleForScaleState(
      scaleStateController.scaleState,
      scaleBoundaries,
    );

    _animateScale!(prevScale, nextScale);
  }

  void addAnimateOnScaleStateUpdate(
    void Function(double prevScale, double nextScale) animateScale,
  ) {
    _animateScale = animateScale;
  }

  void _blindScaleListener() {
    if (!widget.enablePanAlways) {
      controller.position = clampPosition();
    }
    if (controller.scale == controller.prevValue.scale) {
      return;
    }
    final PhotoViewScaleState newScaleState =
        (scale > scaleBoundaries.initialScale)
            ? PhotoViewScaleState.zoomedIn
            : PhotoViewScaleState.zoomedOut;

    scaleStateController.setInvisibly(newScaleState);
  }

  Offset get position => controller.position;

  double get scale {
    final needsRecalc = markNeedsScaleRecalc &&
        !scaleStateController.scaleState.isScaleStateZooming;

    final scaleExistsOnController = controller.scale != null;
    if (needsRecalc || !scaleExistsOnController) {
      final newScale = getScaleForScaleState(
        scaleStateController.scaleState,
        scaleBoundaries,
      );
      markNeedsScaleRecalc = false;
      scale = newScale;
      return newScale;
    }
    return controller.scale!;
  }

  set scale(double scale) => controller.setScaleInvisibly(scale);

  void updateMultiple({
    Offset? position,
    double? scale,
    double? rotation,
    Offset? rotationFocusPoint,
  }) {
    controller.updateMultiple(
      position: position,
      scale: scale,
      rotation: rotation,
      rotationFocusPoint: rotationFocusPoint,
    );
  }

  void updateScaleStateFromNewScale(double newScale) {
    PhotoViewScaleState newScaleState = PhotoViewScaleState.initial;
    if (scale != scaleBoundaries.initialScale) {
      newScaleState = (newScale > scaleBoundaries.initialScale)
          ? PhotoViewScaleState.zoomedIn
          : PhotoViewScaleState.zoomedOut;
    }
    scaleStateController.setInvisibly(newScaleState);
  }

  void nextScaleState() {
    final PhotoViewScaleState scaleState = scaleStateController.scaleState;
    if (scaleState == PhotoViewScaleState.zoomedIn ||
        scaleState == PhotoViewScaleState.zoomedOut) {
      scaleStateController.scaleState = scaleStateCycle(scaleState);
      return;
    }
    final double originalScale = getScaleForScaleState(
      scaleState,
      scaleBoundaries,
    );

    double prevScale = originalScale;
    PhotoViewScaleState prevScaleState = scaleState;
    double nextScale = originalScale;
    PhotoViewScaleState nextScaleState = scaleState;

    do {
      prevScale = nextScale;
      prevScaleState = nextScaleState;
      nextScaleState = scaleStateCycle(prevScaleState);
      nextScale = getScaleForScaleState(nextScaleState, scaleBoundaries);
    } while (prevScale == nextScale && scaleState != nextScaleState);

    if (originalScale == nextScale) {
      return;
    }
    scaleStateController.scaleState = nextScaleState;
  }

  PhotoViewLayoutMetrics layoutMetrics({Offset? position, double? scale}) {
    return PhotoViewLayoutMetrics(
      scaleBoundaries: scaleBoundaries,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      basePosition: basePosition,
    );
  }

  CornersRange cornersX({double? scale}) {
    return layoutMetrics(scale: scale).cornersX();
  }

  CornersRange cornersY({double? scale}) {
    return layoutMetrics(scale: scale).cornersY();
  }

  Offset clampPosition({Offset? position, double? scale}) {
    final metrics = layoutMetrics(position: position, scale: scale);
    return interactionPolicy.clampPosition(
      metrics,
      position ?? this.position,
    );
  }

  @override
  void dispose() {
    _animateScale = null;
    controller.removeIgnorableListener(_blindScaleListener);
    scaleStateController.removeIgnorableListener(_blindScaleStateListener);
    super.dispose();
  }
}
