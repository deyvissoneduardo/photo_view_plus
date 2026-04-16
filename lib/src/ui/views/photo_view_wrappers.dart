import 'package:flutter/widgets.dart';
import 'package:photo_view/src/data/repositories/repositories.dart';
import 'package:photo_view/src/domain/use_cases/use_cases.dart';
import 'package:photo_view/src/ui/view_models/photo_view_image_view_model.dart';

import '../../../photo_view.dart';
import '../../core/photo_view_core.dart';
import '../../photo_view_default_widgets.dart';

class ImageWrapper extends StatefulWidget {
  const ImageWrapper({
    super.key,
    required this.options,
    required this.imageProvider,
    required this.loadingBuilder,
    required this.backgroundDecoration,
    required this.semanticLabel,
    required this.gaplessPlayback,
    required this.heroAttributes,
    required this.scaleStateChangedCallback,
    required this.enableRotation,
    required this.controller,
    required this.scaleStateController,
    required this.maxScale,
    required this.minScale,
    required this.initialScale,
    required this.basePosition,
    required this.scaleStateCycle,
    required this.onTapUp,
    required this.onTapDown,
    required this.onLongPress,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.outerSize,
    required this.errorBuilder,
  });

  final PhotoViewOptions options;
  final ImageProvider imageProvider;
  final LoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final BoxDecoration backgroundDecoration;
  final String? semanticLabel;
  final bool gaplessPlayback;
  final PhotoViewHeroAttributes? heroAttributes;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;
  final bool enableRotation;
  final PhotoViewScale? maxScale;
  final PhotoViewScale? minScale;
  final PhotoViewScale? initialScale;
  final PhotoViewControllerBase controller;
  final PhotoViewScaleStateController scaleStateController;
  final Alignment? basePosition;
  final ScaleStateCycle? scaleStateCycle;
  final PhotoViewImageTapUpCallback? onTapUp;
  final PhotoViewImageTapDownCallback? onTapDown;
  final PhotoViewImageLongPressCallback? onLongPress;
  final PhotoViewImageScaleStartCallback? onScaleStart;
  final PhotoViewImageScaleUpdateCallback? onScaleUpdate;
  final PhotoViewImageScaleEndCallback? onScaleEnd;
  final Size outerSize;

  @override
  State<ImageWrapper> createState() => _ImageWrapperState();
}

class _ImageWrapperState extends State<ImageWrapper> {
  late final PhotoViewImageRepository _imageRepository;
  late final PhotoViewImageViewModel _imageViewModel;

  @override
  void initState() {
    super.initState();
    _imageRepository = PhotoViewImageRepository();
    _imageViewModel = PhotoViewImageViewModel(repository: _imageRepository);
  }

  @override
  void dispose() {
    _imageViewModel.dispose();
    _imageRepository.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(ImageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    _imageViewModel.resolveImage(
      imageProvider: widget.imageProvider,
      configuration: createLocalImageConfiguration(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _imageViewModel,
      builder: (BuildContext context, Widget? child) {
        final imageState = _imageViewModel.state;

        if (imageState.isLoading) {
          return _buildLoading(context, imageState.loadingProgress);
        }

        if (imageState.hasError) {
          return _buildError(
            context,
            imageState.error!,
            imageState.stackTrace,
          );
        }

        final imageSize = imageState.imageSize;
        if (imageSize == null) {
          return _buildLoading(context, imageState.loadingProgress);
        }

        final scaleBoundaries = ScaleBoundaries(
          widget.minScale ?? const PhotoViewScale.fixed(0.0),
          widget.maxScale ?? const PhotoViewScale.fixed(double.infinity),
          widget.initialScale ?? PhotoViewScale.contained,
          widget.outerSize,
          imageSize,
        );

        final child = PhotoViewCore(
          imageProvider: widget.imageProvider,
          backgroundDecoration: widget.backgroundDecoration,
          semanticLabel: widget.semanticLabel,
          gaplessPlayback: widget.gaplessPlayback,
          enableRotation: widget.enableRotation,
          heroAttributes: widget.heroAttributes,
          basePosition: widget.basePosition ?? Alignment.center,
          controller: widget.controller,
          scaleStateController: widget.scaleStateController,
          scaleStateCycle: widget.scaleStateCycle ?? defaultScaleStateCycle,
          scaleBoundaries: scaleBoundaries,
          onTapUp: widget.onTapUp,
          onTapDown: widget.onTapDown,
          onLongPress: widget.onLongPress,
          onScaleStart: widget.onScaleStart,
          onScaleUpdate: widget.onScaleUpdate,
          onScaleEnd: widget.onScaleEnd,
          gestureDetectorBehavior: widget.options.gestureDetectorBehavior,
          tightMode: widget.options.tightMode ?? false,
          filterQuality: widget.options.filterQuality ?? FilterQuality.none,
          disableGestures: widget.options.disableGestures ?? false,
          disableDoubleTap: widget.options.disableDoubleTap ?? false,
          enablePanAlways: widget.options.enablePanAlways ?? false,
          strictScale: widget.options.strictScale ?? false,
          interactionPolicy: widget.options.interactionPolicy ??
              const PhotoViewInteractionPolicy(),
        );

        return _decorate(
          context,
          child: child,
          overlayDetails: _overlayDetails(),
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context, ImageChunkEvent? loadingProgress) {
    final richBuilder = widget.options.loadingStateBuilder;
    final child = _wrapHeroState(
      richBuilder != null
          ? richBuilder(
              context,
              PhotoViewLoadingDetails(
                imageProvider: widget.imageProvider,
                outerSize: widget.outerSize,
                progress: loadingProgress,
              ),
            )
          : widget.loadingBuilder != null
              ? widget.loadingBuilder!(context, loadingProgress)
              : PhotoViewDefaultLoading(
                  event: loadingProgress,
                ),
    );

    return _decorate(
      context,
      child: child,
      overlayDetails: PhotoViewOverlayDetails(
        viewportState: _currentViewportState(),
        scaleState: widget.scaleStateController.scaleState,
        outerSize: widget.outerSize,
        imageProvider: widget.imageProvider,
        isLoading: true,
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final richBuilder = widget.options.errorStateBuilder;
    final child = _wrapHeroState(
      richBuilder != null
          ? richBuilder(
              context,
              PhotoViewErrorDetails(
                imageProvider: widget.imageProvider,
                outerSize: widget.outerSize,
                error: error,
                stackTrace: stackTrace,
              ),
            )
          : widget.errorBuilder != null
              ? widget.errorBuilder!(context, error, stackTrace)
              : PhotoViewDefaultError(
                  decoration: widget.backgroundDecoration,
                ),
    );

    return _decorate(
      context,
      child: child,
      overlayDetails: PhotoViewOverlayDetails(
        viewportState: _currentViewportState(),
        scaleState: widget.scaleStateController.scaleState,
        outerSize: widget.outerSize,
        imageProvider: widget.imageProvider,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  PhotoViewViewportState? _currentViewportState() {
    final value = widget.controller.value;
    final scale = value.scale;
    if (scale == null) {
      return null;
    }

    return PhotoViewViewportState(
      position: value.position,
      scale: scale,
      rotation: value.rotation,
      rotationFocusPoint: value.rotationFocusPoint,
    );
  }

  PhotoViewOverlayDetails _overlayDetails() {
    return PhotoViewOverlayDetails(
      viewportState: _currentViewportState(),
      scaleState: widget.scaleStateController.scaleState,
      outerSize: widget.outerSize,
      imageProvider: widget.imageProvider,
    );
  }

  Widget _wrapHeroState(Widget child) {
    final heroAttributes = widget.heroAttributes;
    if (heroAttributes == null) {
      return child;
    }

    return Hero(
      tag: heroAttributes.tag,
      createRectTween: heroAttributes.createRectTween,
      flightShuttleBuilder: heroAttributes.flightShuttleBuilder,
      placeholderBuilder: heroAttributes.placeholderBuilder,
      transitionOnUserGestures: heroAttributes.transitionOnUserGestures,
      child: child,
    );
  }

  Widget _decorate(
    BuildContext context, {
    required Widget child,
    required PhotoViewOverlayDetails overlayDetails,
  }) {
    Widget current = child;
    if (widget.options.backgroundBuilder != null) {
      current = widget.options.backgroundBuilder!(context, current);
    }

    final overlay =
        widget.options.overlayBuilder?.call(context, overlayDetails);
    if (overlay != null) {
      current = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          current,
          IgnorePointer(child: overlay),
        ],
      );
    }

    if (widget.options.childWrapper != null) {
      current = widget.options.childWrapper!(context, current);
    }

    return current;
  }
}

class CustomChildWrapper extends StatelessWidget {
  const CustomChildWrapper({
    super.key,
    required this.options,
    this.child,
    required this.childSize,
    required this.backgroundDecoration,
    this.heroAttributes,
    this.scaleStateChangedCallback,
    required this.enableRotation,
    required this.controller,
    required this.scaleStateController,
    required this.maxScale,
    required this.minScale,
    required this.initialScale,
    required this.basePosition,
    required this.scaleStateCycle,
    this.onTapUp,
    this.onTapDown,
    this.onLongPress,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    required this.outerSize,
  });

  final PhotoViewOptions options;
  final Widget? child;
  final Size? childSize;
  final Decoration backgroundDecoration;
  final PhotoViewHeroAttributes? heroAttributes;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;
  final bool enableRotation;
  final PhotoViewControllerBase controller;
  final PhotoViewScaleStateController scaleStateController;
  final PhotoViewScale? maxScale;
  final PhotoViewScale? minScale;
  final PhotoViewScale? initialScale;
  final Alignment? basePosition;
  final ScaleStateCycle? scaleStateCycle;
  final PhotoViewImageTapUpCallback? onTapUp;
  final PhotoViewImageTapDownCallback? onTapDown;
  final PhotoViewImageLongPressCallback? onLongPress;
  final PhotoViewImageScaleStartCallback? onScaleStart;
  final PhotoViewImageScaleUpdateCallback? onScaleUpdate;
  final PhotoViewImageScaleEndCallback? onScaleEnd;
  final Size outerSize;

  @override
  Widget build(BuildContext context) {
    final scaleBoundaries = ScaleBoundaries(
      minScale ?? const PhotoViewScale.fixed(0.0),
      maxScale ?? const PhotoViewScale.fixed(double.infinity),
      initialScale ?? PhotoViewScale.contained,
      outerSize,
      childSize ?? outerSize,
    );

    Widget current = PhotoViewCore.customChild(
      customChild: child,
      backgroundDecoration: backgroundDecoration,
      enableRotation: enableRotation,
      heroAttributes: heroAttributes,
      controller: controller,
      scaleStateController: scaleStateController,
      scaleStateCycle: scaleStateCycle ?? defaultScaleStateCycle,
      basePosition: basePosition ?? Alignment.center,
      scaleBoundaries: scaleBoundaries,
      strictScale: options.strictScale ?? false,
      onTapUp: onTapUp,
      onTapDown: onTapDown,
      onLongPress: onLongPress,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      gestureDetectorBehavior: options.gestureDetectorBehavior,
      tightMode: options.tightMode ?? false,
      filterQuality: options.filterQuality ?? FilterQuality.none,
      disableGestures: options.disableGestures ?? false,
      disableDoubleTap: options.disableDoubleTap ?? false,
      enablePanAlways: options.enablePanAlways ?? false,
      interactionPolicy:
          options.interactionPolicy ?? const PhotoViewInteractionPolicy(),
    );

    if (options.backgroundBuilder != null) {
      current = options.backgroundBuilder!(context, current);
    }

    final overlay = options.overlayBuilder?.call(
      context,
      PhotoViewOverlayDetails(
        viewportState: null,
        scaleState: scaleStateController.scaleState,
        outerSize: outerSize,
      ),
    );

    if (overlay != null) {
      current = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          current,
          IgnorePointer(child: overlay),
        ],
      );
    }

    if (options.childWrapper != null) {
      current = options.childWrapper!(context, current);
    }

    return current;
  }
}
