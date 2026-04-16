import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_view_plus/photo_view_plus.dart'
    show
        PhotoViewScaleState,
        PhotoViewHeroAttributes,
        PhotoViewImageLongPressCallback,
        PhotoViewImageTapDownCallback,
        PhotoViewImageTapUpCallback,
        PhotoViewImageScaleStartCallback,
        PhotoViewImageScaleUpdateCallback,
        PhotoViewImageScaleEndCallback,
        ScaleStateCycle;
import 'package:photo_view_plus/src/core/photo_view_gesture_detector.dart';
import 'package:photo_view_plus/src/domain/models/models.dart';
import 'package:photo_view_plus/src/domain/use_cases/use_cases.dart';
import 'package:photo_view_plus/src/ui/coordinators/photo_view_return_coordinator.dart';
import 'package:photo_view_plus/src/ui/view_models/view_models.dart';

const _defaultDecoration = BoxDecoration(
  color: Color.fromRGBO(0, 0, 0, 1.0),
);

/// Internal widget in which controls all animations lifecycle, core responses
/// to user gestures, updates to  the controller state and mounts the entire PhotoView Layout
class PhotoViewCore extends StatefulWidget {
  const PhotoViewCore({
    super.key,
    required this.imageProvider,
    required this.backgroundDecoration,
    required this.semanticLabel,
    required this.gaplessPlayback,
    required this.heroAttributes,
    required this.enableRotation,
    required this.onTapUp,
    required this.onTapDown,
    required this.onLongPress,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.gestureDetectorBehavior,
    required this.controller,
    required this.scaleBoundaries,
    required this.scaleStateCycle,
    required this.scaleStateController,
    required this.basePosition,
    required this.tightMode,
    required this.filterQuality,
    required this.disableGestures,
    required this.disableDoubleTap,
    required this.enablePanAlways,
    required this.strictScale,
    required this.interactionPolicy,
  }) : customChild = null;

  const PhotoViewCore.customChild({
    super.key,
    required this.customChild,
    required this.backgroundDecoration,
    this.heroAttributes,
    required this.enableRotation,
    this.onTapUp,
    this.onTapDown,
    this.onLongPress,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.gestureDetectorBehavior,
    required this.controller,
    required this.scaleBoundaries,
    required this.scaleStateCycle,
    required this.scaleStateController,
    required this.basePosition,
    required this.tightMode,
    required this.filterQuality,
    required this.disableGestures,
    required this.disableDoubleTap,
    required this.enablePanAlways,
    required this.strictScale,
    required this.interactionPolicy,
  })  : imageProvider = null,
        semanticLabel = null,
        gaplessPlayback = false;

  final Decoration? backgroundDecoration;
  final ImageProvider? imageProvider;
  final String? semanticLabel;
  final bool? gaplessPlayback;
  final PhotoViewHeroAttributes? heroAttributes;
  final bool enableRotation;
  final Widget? customChild;

  final PhotoViewControllerBase controller;
  final PhotoViewScaleStateController scaleStateController;
  final ScaleBoundaries scaleBoundaries;
  final ScaleStateCycle scaleStateCycle;
  final Alignment basePosition;

  final PhotoViewImageTapUpCallback? onTapUp;
  final PhotoViewImageTapDownCallback? onTapDown;
  final PhotoViewImageLongPressCallback? onLongPress;
  final PhotoViewImageScaleStartCallback? onScaleStart;
  final PhotoViewImageScaleUpdateCallback? onScaleUpdate;
  final PhotoViewImageScaleEndCallback? onScaleEnd;

  final HitTestBehavior? gestureDetectorBehavior;
  final bool tightMode;
  final bool disableGestures;
  final bool disableDoubleTap;
  final bool enablePanAlways;
  final bool strictScale;
  final PhotoViewInteractionPolicy interactionPolicy;

  final FilterQuality filterQuality;

  @override
  State<StatefulWidget> createState() {
    return PhotoViewCoreState();
  }

  bool get hasCustomChild => customChild != null;
}

class PhotoViewCoreState extends State<PhotoViewCore>
    with
        TickerProviderStateMixin,
        PhotoViewControllerDelegate,
        HitCornersDetector {
  Offset? _normalizedPosition;
  double? _scaleBefore;
  double? _rotationBefore;
  bool _isGestureActive = false;
  bool _isMouseDragging = false;
  bool _isMouseHoveringContent = false;
  Offset? _lastMouseLocalPosition;

  late final AnimationController _scaleAnimationController;
  Animation<double>? _scaleAnimation;

  late final AnimationController _positionAnimationController;
  Animation<Offset>? _positionAnimation;

  late final AnimationController _rotationAnimationController =
      AnimationController(vsync: this)..addListener(handleRotationAnimation);
  Animation<double>? _rotationAnimation;

  PhotoViewHeroAttributes? get heroAttributes => widget.heroAttributes;

  late ScaleBoundaries cachedScaleBoundaries = widget.scaleBoundaries;
  static const _returnCoordinator = PhotoViewReturnCoordinator();

  PhotoViewViewportState get _viewportState => PhotoViewViewportState(
        position: controller.position,
        scale: scale,
        rotation: controller.rotation,
        rotationFocusPoint: controller.rotationFocusPoint,
      );

  void handleScaleAnimation() {
    scale = _scaleAnimation!.value;
  }

  void handlePositionAnimate() {
    controller.position = _positionAnimation!.value;
  }

  void handleRotationAnimation() {
    controller.rotation = _rotationAnimation!.value;
  }

  void onScaleStart(ScaleStartDetails details) {
    _isGestureActive = true;
    _rotationBefore = controller.rotation;
    _scaleBefore = scale;
    final transformOrigin =
        widget.basePosition.alongSize(widget.scaleBoundaries.outerSize);
    _normalizedPosition =
        details.focalPoint - transformOrigin - controller.position;
    _scaleAnimationController.stop();
    _positionAnimationController.stop();
    _rotationAnimationController.stop();
    widget.onScaleStart?.call(context, details, controller.value);
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    final double newScale = _scaleBefore! * details.scale;
    final transformOrigin =
        widget.basePosition.alongSize(widget.scaleBoundaries.outerSize);
    final delta = _normalizedPosition! * details.scale;
    final newPosition = details.focalPoint - transformOrigin - delta;

    if (widget.strictScale &&
        (newScale > widget.scaleBoundaries.maxScale ||
            newScale < widget.scaleBoundaries.minScale)) {
      return;
    }

    updateScaleStateFromNewScale(newScale);

    updateMultiple(
      scale: newScale,
      position: widget.enablePanAlways
          ? newPosition
          : clampPosition(position: newPosition),
      rotation:
          widget.enableRotation ? _rotationBefore! + details.rotation : null,
      rotationFocusPoint: widget.enableRotation ? details.focalPoint : null,
    );
    widget.onScaleUpdate?.call(context, details, controller.value);
  }

  void onScaleEnd(ScaleEndDetails details) {
    _isGestureActive = false;
    final double currentScale = scale;
    final Offset currentPosition = controller.position;

    widget.onScaleEnd?.call(context, details, controller.value);

    final gestureEndResult = _returnCoordinator.resolve(
      interactionPolicy: widget.interactionPolicy,
      viewportState: _viewportState,
      layoutMetrics: layoutMetrics(),
      scaleBoundaries: scaleBoundaries,
      scaleBefore: _scaleBefore ?? currentScale,
      velocity: details.velocity,
    );

    if (gestureEndResult.hasScaleAnimation) {
      animateScale(currentScale, gestureEndResult.targetScale!);
    }

    if (gestureEndResult.hasPositionAnimation) {
      animatePosition(currentPosition, gestureEndResult.targetPosition!);
    }

    if (gestureEndResult.hasScaleAnimation ||
        gestureEndResult.hasPositionAnimation) {
      return;
    }
  }

  void onDoubleTap() {
    nextScaleState();
  }

  Offset get _transformOrigin =>
      widget.basePosition.alongSize(widget.scaleBoundaries.outerSize);

  void _panBy(Offset delta) {
    final nextPosition = controller.position + delta;
    controller.position = widget.enablePanAlways
        ? nextPosition
        : clampPosition(position: nextPosition);
  }

  void _zoomBy(double factor, Offset focalPoint) {
    final currentScale = scale;
    final targetScale = (currentScale * factor).clamp(
      widget.scaleBoundaries.minScale,
      widget.scaleBoundaries.maxScale,
    );

    if (widget.strictScale && targetScale == currentScale) {
      return;
    }

    final focalVector = focalPoint - _transformOrigin - controller.position;
    final normalizedVector = focalVector / currentScale;
    final nextPosition =
        focalPoint - _transformOrigin - (normalizedVector * targetScale);

    updateScaleStateFromNewScale(targetScale);
    updateMultiple(
      scale: targetScale,
      position: widget.enablePanAlways
          ? nextPosition
          : clampPosition(position: nextPosition, scale: targetScale),
    );
  }

  bool _hitTestContent(Offset localPosition) {
    final currentScale = scale;
    if (currentScale == 0) {
      return false;
    }

    final centeredLeft = (widget.scaleBoundaries.outerSize.width -
            widget.scaleBoundaries.childSize.width) /
        2;
    final centeredTop = (widget.scaleBoundaries.outerSize.height -
            widget.scaleBoundaries.childSize.height) /
        2;
    final alignedLeft = centeredLeft + centeredLeft * widget.basePosition.x;
    final alignedTop = centeredTop + centeredTop * widget.basePosition.y;
    final baseRect = Rect.fromLTWH(
      alignedLeft,
      alignedTop,
      widget.scaleBoundaries.childSize.width,
      widget.scaleBoundaries.childSize.height,
    );

    var point = localPosition - _transformOrigin;
    point -= controller.position;
    point = Offset(point.dx / currentScale, point.dy / currentScale);

    if (controller.rotation != 0) {
      final cosTheta = math.cos(-controller.rotation);
      final sinTheta = math.sin(-controller.rotation);
      point = Offset(
        point.dx * cosTheta - point.dy * sinTheta,
        point.dx * sinTheta + point.dy * cosTheta,
      );
    }

    point += _transformOrigin;
    return baseRect.contains(point);
  }

  void _updateMouseHoverState([Offset? localPosition]) {
    final position = localPosition ?? _lastMouseLocalPosition;
    if (position == null || _isMouseDragging) {
      return;
    }

    final hovering = _hitTestContent(position);
    if (hovering != _isMouseHoveringContent) {
      setState(() {
        _isMouseHoveringContent = hovering;
      });
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.kind != PointerDeviceKind.mouse) {
      return;
    }

    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrlPressed = keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
    final shiftPressed = keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);

    if (ctrlPressed) {
      final zoomFactor = event.scrollDelta.dy > 0 ? 0.95 : 1.05;
      _zoomBy(zoomFactor, event.localPosition);
      _updateMouseHoverState(event.localPosition);
      return;
    }

    var deltaX = -event.scrollDelta.dx;
    var deltaY = -event.scrollDelta.dy;
    if (shiftPressed && deltaX == 0.0) {
      deltaX = deltaY;
      deltaY = 0.0;
    }

    _panBy(Offset(deltaX, deltaY));
    _updateMouseHoverState(event.localPosition);
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (event.scale != 1.0) {
      _zoomBy(event.scale, event.localPosition);
    }
    if (event.panDelta != Offset.zero) {
      _panBy(event.panDelta);
    }
  }

  void animateScale(double from, double to) {
    _scaleAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(_scaleAnimationController);
    _scaleAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void animatePosition(Offset from, Offset to) {
    _positionAnimation = Tween<Offset>(begin: from, end: to)
        .animate(_positionAnimationController);
    _positionAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void animateRotation(double from, double to) {
    _rotationAnimation = Tween<double>(begin: from, end: to)
        .animate(_rotationAnimationController);
    _rotationAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      onAnimationStatusCompleted();
    }
  }

  /// Check if scale is equal to initial after scale animation update
  void onAnimationStatusCompleted() {
    if (scaleStateController.scaleState != PhotoViewScaleState.initial &&
        scale == scaleBoundaries.initialScale) {
      scaleStateController.setInvisibly(PhotoViewScaleState.initial);
    }
  }

  @override
  void initState() {
    super.initState();
    initDelegate();
    addAnimateOnScaleStateUpdate(animateOnScaleStateUpdate);

    cachedScaleBoundaries = widget.scaleBoundaries;

    _scaleAnimationController = AnimationController(vsync: this)
      ..addListener(handleScaleAnimation)
      ..addStatusListener(onAnimationStatus);
    _positionAnimationController = AnimationController(vsync: this)
      ..addListener(handlePositionAnimate);
  }

  void animateOnScaleStateUpdate(double prevScale, double nextScale) {
    animateScale(prevScale, nextScale);
    animatePosition(controller.position, Offset.zero);
    animateRotation(controller.rotation, 0.0);
  }

  @override
  void dispose() {
    _scaleAnimationController.removeStatusListener(onAnimationStatus);
    _scaleAnimationController.dispose();
    _positionAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  void onTapUp(TapUpDetails details) {
    widget.onTapUp?.call(context, details, controller.value);
  }

  void onTapDown(TapDownDetails details) {
    widget.onTapDown?.call(context, details, controller.value);
  }

  void onLongPress() {
    widget.onLongPress?.call(context, controller.value);
  }

  @override
  Widget build(BuildContext context) {
    // Check if we need a recalc on the scale
    if (widget.scaleBoundaries != cachedScaleBoundaries) {
      markNeedsScaleRecalc = true;
      cachedScaleBoundaries = widget.scaleBoundaries;
    }

    return StreamBuilder(
        stream: controller.outputStateStream,
        initialData: controller.prevValue,
        builder: (
          BuildContext context,
          AsyncSnapshot<PhotoViewControllerValue> snapshot,
        ) {
          if (snapshot.hasData) {
            final PhotoViewControllerValue value = snapshot.data!;
            final activeFilterQuality = widget.interactionPolicy.filterQuality(
              PhotoViewFilterQualityContext(
                viewportState: _viewportState,
                scaleState: scaleStateController.scaleState,
                preferredQuality: widget.filterQuality,
                isGestureActive: _isGestureActive,
              ),
            );
            final useImageScale = activeFilterQuality != FilterQuality.none;

            final computedScale = useImageScale ? 1.0 : scale;

            final matrix = Matrix4.identity()
              ..translateByDouble(
                  value.position.dx, value.position.dy, 0.0, 1.0)
              ..scaleByDouble(computedScale, computedScale, 1.0, 1.0)
              ..rotateZ(value.rotation);

            final Widget customChildLayout = CustomSingleChildLayout(
              delegate: _CenterWithOriginalSizeDelegate(
                scaleBoundaries.childSize,
                basePosition,
                useImageScale,
              ),
              child: _buildHero(activeFilterQuality),
            );

            Widget child = Container(
              constraints: widget.tightMode
                  ? BoxConstraints.tight(scaleBoundaries.childSize * scale)
                  : null,
              decoration: widget.backgroundDecoration ?? _defaultDecoration,
              child: Center(
                child: Transform(
                  transform: matrix,
                  alignment: basePosition,
                  child: customChildLayout,
                ),
              ),
            );

            if (widget.disableGestures) {
              return child;
            }

            child = PhotoViewGestureDetector(
              onDoubleTap: widget.disableDoubleTap ? null : nextScaleState,
              onScaleStart: onScaleStart,
              onScaleUpdate: onScaleUpdate,
              onScaleEnd: onScaleEnd,
              hitDetector: this,
              onTapUp: widget.onTapUp != null
                  ? (details) => widget.onTapUp!(context, details, value)
                  : null,
              onTapDown: widget.onTapDown != null
                  ? (details) => widget.onTapDown!(context, details, value)
                  : null,
              onLongPress: widget.onLongPress != null ? onLongPress : null,
              child: child,
            );

            child = Listener(
              behavior: HitTestBehavior.translucent,
              onPointerSignal: _onPointerSignal,
              onPointerPanZoomUpdate: _onPointerPanZoomUpdate,
              onPointerDown: (event) {
                if (event.kind != PointerDeviceKind.mouse ||
                    event.buttons != kPrimaryMouseButton) {
                  return;
                }
                _lastMouseLocalPosition = event.localPosition;
                final hovering = _hitTestContent(event.localPosition);
                setState(() {
                  _isMouseDragging = hovering;
                  _isMouseHoveringContent = hovering;
                });
              },
              onPointerUp: (event) {
                if (event.kind != PointerDeviceKind.mouse) {
                  return;
                }
                _lastMouseLocalPosition = event.localPosition;
                setState(() {
                  _isMouseDragging = false;
                });
                _updateMouseHoverState(event.localPosition);
              },
              onPointerCancel: (event) {
                if (event.kind != PointerDeviceKind.mouse) {
                  return;
                }
                setState(() {
                  _isMouseDragging = false;
                });
              },
              child: MouseRegion(
                opaque: false,
                hitTestBehavior: HitTestBehavior.translucent,
                cursor: _isMouseDragging
                    ? SystemMouseCursors.grabbing
                    : _isMouseHoveringContent
                        ? SystemMouseCursors.grab
                        : MouseCursor.defer,
                onHover: (event) {
                  _lastMouseLocalPosition = event.localPosition;
                  _updateMouseHoverState(event.localPosition);
                },
                onEnter: (event) {
                  _lastMouseLocalPosition = event.localPosition;
                  _updateMouseHoverState(event.localPosition);
                },
                onExit: (event) {
                  _lastMouseLocalPosition = null;
                  if (_isMouseDragging || _isMouseHoveringContent) {
                    setState(() {
                      _isMouseDragging = false;
                      _isMouseHoveringContent = false;
                    });
                  }
                },
                child: child,
              ),
            );

            return child;
          } else {
            return Container();
          }
        });
  }

  Widget _buildHero(FilterQuality filterQuality) {
    return heroAttributes != null
        ? Hero(
            tag: heroAttributes!.tag,
            createRectTween: heroAttributes!.createRectTween,
            flightShuttleBuilder: heroAttributes!.flightShuttleBuilder,
            placeholderBuilder: heroAttributes!.placeholderBuilder,
            transitionOnUserGestures: heroAttributes!.transitionOnUserGestures,
            child: _buildChild(filterQuality),
          )
        : _buildChild(filterQuality);
  }

  Widget _buildChild(FilterQuality filterQuality) {
    return widget.hasCustomChild
        ? widget.customChild!
        : Image(
            image: widget.imageProvider!,
            semanticLabel: widget.semanticLabel,
            gaplessPlayback: widget.gaplessPlayback ?? false,
            filterQuality: filterQuality,
            width: scaleBoundaries.childSize.width * scale,
            fit: BoxFit.contain,
          );
  }
}

class _CenterWithOriginalSizeDelegate extends SingleChildLayoutDelegate {
  const _CenterWithOriginalSizeDelegate(
    this.subjectSize,
    this.basePosition,
    this.useImageScale,
  );

  final Size subjectSize;
  final Alignment basePosition;
  final bool useImageScale;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final childWidth = useImageScale ? childSize.width : subjectSize.width;
    final childHeight = useImageScale ? childSize.height : subjectSize.height;

    final halfWidth = (size.width - childWidth) / 2;
    final halfHeight = (size.height - childHeight) / 2;

    final double offsetX = halfWidth * (basePosition.x + 1);
    final double offsetY = halfHeight * (basePosition.y + 1);
    return Offset(offsetX, offsetY);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return useImageScale
        ? const BoxConstraints()
        : BoxConstraints.tight(subjectSize);
  }

  @override
  bool shouldRelayout(_CenterWithOriginalSizeDelegate oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CenterWithOriginalSizeDelegate &&
          runtimeType == other.runtimeType &&
          subjectSize == other.subjectSize &&
          basePosition == other.basePosition &&
          useImageScale == other.useImageScale;

  @override
  int get hashCode =>
      subjectSize.hashCode ^ basePosition.hashCode ^ useImageScale.hashCode;
}
