import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_view/photo_view.dart'
    show
        LoadingBuilder,
        PhotoView,
        PhotoViewScale,
        PhotoViewImageLongPressCallback,
        PhotoViewImageTapDownCallback,
        PhotoViewImageTapUpCallback,
        PhotoViewImageScaleStartCallback,
        PhotoViewImageScaleUpdateCallback,
        PhotoViewImageScaleEndCallback,
        ScaleStateCycle;
import 'package:photo_view/src/domain/models/models.dart';
import 'package:photo_view/src/ui/view_models/view_models.dart';
import 'package:photo_view/src/ui/views/views.dart';

/// A type definition for a [Function] that receives a index after a page change in [PhotoViewGallery]
typedef PhotoViewGalleryPageChangedCallback = void Function(int index);

/// A type definition for a [Function] that defines a page in [PhotoViewGallery.build]
typedef PhotoViewGalleryBuilder = PhotoViewGalleryPageOptions Function(
    BuildContext context, int index);

/// A [StatefulWidget] that shows multiple [PhotoView] widgets in a [PageView]
///
/// Some of [PhotoView] constructor options are passed direct to [PhotoViewGallery] constructor. Those options will affect the gallery in a whole.
///
/// Some of the options may be defined to each image individually, such as `initialScale` or `PhotoViewHeroAttributes`. Those must be passed via each [PhotoViewGalleryPageOptions].
///
/// Example of usage as a list of options:
/// ```
/// PhotoViewGallery(
///   pageOptions: <PhotoViewGalleryPageOptions>[
///     PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage("assets/gallery1.jpg"),
///       heroAttributes: const PhotoViewHeroAttributes(tag: "tag1"),
///     ),
///     PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage("assets/gallery2.jpg"),
///       heroAttributes: const PhotoViewHeroAttributes(tag: "tag2"),
///       maxScale: PhotoViewComputedScale.contained * 0.3
///     ),
///     PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage("assets/gallery3.jpg"),
///       minScale: PhotoViewComputedScale.contained * 0.8,
///       maxScale: PhotoViewComputedScale.covered * 1.1,
///       heroAttributes: const HeroAttributes(tag: "tag3"),
///     ),
///   ],
///   loadingBuilder: (context, progress) => Center(
///            child: Container(
///              width: 20.0,
///              height: 20.0,
///              child: CircularProgressIndicator(
///                value: _progress == null
///                    ? null
///                    : _progress.cumulativeBytesLoaded /
///                        _progress.expectedTotalBytes,
///              ),
///            ),
///          ),
///   backgroundDecoration: widget.backgroundDecoration,
///   pageController: widget.pageController,
///   onPageChanged: onPageChanged,
/// )
/// ```
///
/// Example of usage with builder pattern:
/// ```
/// PhotoViewGallery.builder(
///   scrollPhysics: const BouncingScrollPhysics(),
///   builder: (BuildContext context, int index) {
///     return PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage(widget.galleryItems[index].image),
///       initialScale: PhotoViewComputedScale.contained * 0.8,
///       minScale: PhotoViewComputedScale.contained * 0.8,
///       maxScale: PhotoViewComputedScale.covered * 1.1,
///       heroAttributes: HeroAttributes(tag: galleryItems[index].id),
///     );
///   },
///   itemCount: galleryItems.length,
///   loadingBuilder: (context, progress) => Center(
///            child: Container(
///              width: 20.0,
///              height: 20.0,
///              child: CircularProgressIndicator(
///                value: _progress == null
///                    ? null
///                    : _progress.cumulativeBytesLoaded /
///                        _progress.expectedTotalBytes,
///              ),
///            ),
///          ),
///   backgroundDecoration: widget.backgroundDecoration,
///   pageController: widget.pageController,
///   onPageChanged: onPageChanged,
/// )
/// ```
class PhotoViewGallery extends StatefulWidget {
  /// Construct a gallery with static items through a list of [PhotoViewGalleryPageOptions].
  const PhotoViewGallery({
    super.key,
    required this.pageOptions,
    this.options,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.allowImplicitScrolling = false,
    this.pageSnapping = true,
    this.childWrapper,
  })  : itemCount = null,
        builder = null;

  /// Construct a gallery with dynamic items.
  ///
  /// The builder must return a [PhotoViewGalleryPageOptions].
  const PhotoViewGallery.builder({
    super.key,
    required this.itemCount,
    required this.builder,
    this.options,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.allowImplicitScrolling = false,
    this.pageSnapping = true,
    this.childWrapper,
  })  : pageOptions = null,
        assert(itemCount != null),
        assert(builder != null);

  /// A list of options to describe the items in the gallery
  final List<PhotoViewGalleryPageOptions>? pageOptions;
  final PhotoViewGalleryOptions? options;

  /// The count of items in the gallery, only used when constructed via [PhotoViewGallery.builder]
  final int? itemCount;

  /// Called to build items for the gallery when using [PhotoViewGallery.builder]
  final PhotoViewGalleryBuilder? builder;

  /// [ScrollPhysics] for the internal [PageView]
  final ScrollPhysics? scrollPhysics;

  /// Mirror to [PhotoView.loadingBuilder]
  final LoadingBuilder? loadingBuilder;

  /// Mirror to [PhotoView.backgroundDecoration]
  final BoxDecoration? backgroundDecoration;

  /// Mirror to [PhotoView.wantKeepAlive]
  final bool wantKeepAlive;

  /// Mirror to [PhotoView.gaplessPlayback]
  final bool gaplessPlayback;

  /// Mirror to [PageView.reverse]
  final bool reverse;

  /// An object that controls the [PageView] inside [PhotoViewGallery]
  final PageController? pageController;

  /// An callback to be called on a page change
  final PhotoViewGalleryPageChangedCallback? onPageChanged;

  /// Mirror to [PhotoView.scaleStateChangedCallback]
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  /// Mirror to [PhotoView.enableRotation]
  final bool enableRotation;

  /// Mirror to [PhotoView.customSize]
  final Size? customSize;

  /// The axis along which the [PageView] scrolls. Mirror to [PageView.scrollDirection]
  final Axis scrollDirection;

  /// When user attempts to move it to the next element, focus will traverse to the next page in the page view.
  final bool allowImplicitScrolling;

  final bool pageSnapping;

  final PhotoViewGalleryChildWrapper? childWrapper;

  bool get _isBuilder => builder != null;

  @override
  State<StatefulWidget> createState() {
    return _PhotoViewGalleryState();
  }
}

class _PhotoViewGalleryState extends State<PhotoViewGallery> {
  late final PageController _controller =
      widget.pageController ?? PageController();
  final Map<int, PhotoViewGalleryPageOptions> _pageOptionCache =
      <int, PhotoViewGalleryPageOptions>{};

  void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    if (widget.scaleStateChangedCallback != null) {
      widget.scaleStateChangedCallback!(scaleState);
    }
  }

  int get actualPage {
    return _controller.hasClients ? _controller.page!.floor() : 0;
  }

  int get itemCount {
    if (widget._isBuilder) {
      return widget.itemCount!;
    }
    return widget.pageOptions!.length;
  }

  PhotoViewGalleryOptions get _resolvedGalleryOptions {
    final options = widget.options ?? const PhotoViewGalleryOptions();
    return PhotoViewGalleryOptions(
      scrollPhysics: widget.scrollPhysics ?? options.scrollPhysics,
      scrollDirection: widget.scrollDirection,
      allowImplicitScrolling: widget.allowImplicitScrolling ||
          (options.allowImplicitScrolling ?? false),
      pageSnapping: widget.pageSnapping,
      preloadPagesCount: options.preloadPagesCount ?? 1,
      pageRetentionPolicy: options.pageRetentionPolicy ??
          (widget.wantKeepAlive
              ? PhotoViewGalleryPageRetentionPolicy.keepAlive
              : PhotoViewGalleryPageRetentionPolicy.reset),
      options: options.options,
      childWrapper: widget.childWrapper ?? options.childWrapper,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAround(_controller.initialPage);
  }

  @override
  Widget build(BuildContext context) {
    final galleryOptions = _resolvedGalleryOptions;
    // Enable corner hit test
    return PhotoViewGestureDetectorScope(
      axis: galleryOptions.scrollDirection ?? widget.scrollDirection,
      child: PageView.builder(
        reverse: widget.reverse,
        controller: _controller,
        onPageChanged: (index) {
          _precacheAround(index);
          widget.onPageChanged?.call(index);
        },
        itemCount: itemCount,
        itemBuilder: _buildItem,
        scrollDirection:
            galleryOptions.scrollDirection ?? widget.scrollDirection,
        physics: galleryOptions.scrollPhysics ?? widget.scrollPhysics,
        allowImplicitScrolling: galleryOptions.allowImplicitScrolling ??
            widget.allowImplicitScrolling,
        pageSnapping: galleryOptions.pageSnapping ?? widget.pageSnapping,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final galleryOptions = _resolvedGalleryOptions;
    final pageOption = _buildPageOption(context, index);
    final globalOptions = galleryOptions.options ?? const PhotoViewOptions();
    final resolvedOptions = globalOptions.copyWith(
      backgroundDecoration: pageOption.options?.backgroundDecoration ??
          globalOptions.backgroundDecoration,
      wantKeepAlive: (pageOption.options?.wantKeepAlive ?? false) ||
          ((galleryOptions.pageRetentionPolicy ??
                  PhotoViewGalleryPageRetentionPolicy.reset) ==
              PhotoViewGalleryPageRetentionPolicy.keepAlive),
      customSize: widget.customSize ?? globalOptions.customSize,
      gestureDetectorBehavior: pageOption.gestureDetectorBehavior ??
          pageOption.options?.gestureDetectorBehavior ??
          globalOptions.gestureDetectorBehavior,
      tightMode: pageOption.tightMode ??
          pageOption.options?.tightMode ??
          globalOptions.tightMode,
      filterQuality: pageOption.filterQuality ??
          pageOption.options?.filterQuality ??
          globalOptions.filterQuality,
      disableGestures: pageOption.disableGestures ??
          pageOption.options?.disableGestures ??
          globalOptions.disableGestures,
      enablePanAlways:
          pageOption.options?.enablePanAlways ?? globalOptions.enablePanAlways,
      strictScale: pageOption.strictScale ??
          pageOption.options?.strictScale ??
          globalOptions.strictScale,
      disableDoubleTap: pageOption.disableDoubleTap ??
          pageOption.options?.disableDoubleTap ??
          globalOptions.disableDoubleTap,
      interactionPolicy: pageOption.options?.interactionPolicy ??
          globalOptions.interactionPolicy,
      overlayBuilder:
          pageOption.options?.overlayBuilder ?? globalOptions.overlayBuilder,
      backgroundBuilder: pageOption.options?.backgroundBuilder ??
          globalOptions.backgroundBuilder,
      loadingStateBuilder: pageOption.options?.loadingStateBuilder ??
          globalOptions.loadingStateBuilder,
      errorStateBuilder: pageOption.options?.errorStateBuilder ??
          globalOptions.errorStateBuilder,
      childWrapper:
          pageOption.options?.childWrapper ?? globalOptions.childWrapper,
    );
    final isCustomChild = pageOption.child != null;

    final PhotoView photoView = isCustomChild
        ? PhotoView.customChild(
            key: pageOption.pageKey ?? ObjectKey(index),
            options: resolvedOptions,
            childSize: pageOption.childSize,
            backgroundDecoration: widget.backgroundDecoration,
            controller: pageOption.controller,
            scaleStateController: pageOption.scaleStateController,
            customSize: widget.customSize,
            heroAttributes: pageOption.heroAttributes,
            scaleStateChangedCallback: scaleStateChangedCallback,
            enableRotation: widget.enableRotation,
            initialScale: pageOption.initialScale,
            minScale: pageOption.minScale,
            maxScale: pageOption.maxScale,
            scaleStateCycle: pageOption.scaleStateCycle,
            onTapUp: pageOption.onTapUp,
            onTapDown: pageOption.onTapDown,
            onLongPress: pageOption.onLongPress,
            onScaleStart: pageOption.onScaleStart,
            onScaleUpdate: pageOption.onScaleUpdate,
            onScaleEnd: pageOption.onScaleEnd,
            basePosition: pageOption.basePosition,
            child: pageOption.child,
          )
        : PhotoView(
            key: pageOption.pageKey ?? ObjectKey(index),
            options: resolvedOptions,
            imageProvider: pageOption.imageProvider,
            loadingBuilder: widget.loadingBuilder,
            backgroundDecoration: widget.backgroundDecoration,
            controller: pageOption.controller,
            scaleStateController: pageOption.scaleStateController,
            customSize: widget.customSize,
            semanticLabel: pageOption.semanticLabel,
            gaplessPlayback: widget.gaplessPlayback,
            heroAttributes: pageOption.heroAttributes,
            scaleStateChangedCallback: scaleStateChangedCallback,
            enableRotation: widget.enableRotation,
            initialScale: pageOption.initialScale,
            minScale: pageOption.minScale,
            maxScale: pageOption.maxScale,
            scaleStateCycle: pageOption.scaleStateCycle,
            onTapUp: pageOption.onTapUp,
            onTapDown: pageOption.onTapDown,
            onLongPress: pageOption.onLongPress,
            onScaleStart: pageOption.onScaleStart,
            onScaleUpdate: pageOption.onScaleUpdate,
            onScaleEnd: pageOption.onScaleEnd,
            basePosition: pageOption.basePosition,
            errorBuilder: pageOption.errorBuilder,
          );

    final wrappedChild = ClipRect(
      child: photoView,
    );

    final childWrapper = pageOption.childWrapper ?? galleryOptions.childWrapper;
    if (childWrapper == null) {
      return wrappedChild;
    }

    return childWrapper(context, index, wrappedChild);
  }

  PhotoViewGalleryPageOptions _buildPageOption(
      BuildContext context, int index) {
    final cached = _pageOptionCache[index];
    if (cached != null) {
      return cached;
    }
    if (widget._isBuilder) {
      final option = widget.builder!(context, index);
      _pageOptionCache[index] = option;
      return option;
    }
    return widget.pageOptions![index];
  }

  void _precacheAround(int centerIndex) {
    final preloadCount = _resolvedGalleryOptions.preloadPagesCount ?? 1;
    for (var offset = 0; offset <= preloadCount; offset++) {
      _precacheIndex(centerIndex - offset);
      _precacheIndex(centerIndex + offset);
    }
  }

  void _precacheIndex(int index) {
    if (index < 0 || index >= itemCount) {
      return;
    }
    final option = _buildPageOption(context, index);
    if (option.imageProvider != null) {
      precacheImage(option.imageProvider!, context);
    }
  }
}

/// A helper class that wraps individual options of a page in [PhotoViewGallery]
///
/// The [maxScale], [minScale] and [initialScale] options may be [double] or a [PhotoViewComputedScale] constant
///
class PhotoViewGalleryPageOptions {
  PhotoViewGalleryPageOptions({
    Key? key,
    required this.imageProvider,
    this.pageKey,
    this.options,
    this.heroAttributes,
    this.semanticLabel,
    this.minScale,
    this.maxScale,
    this.strictScale,
    this.initialScale,
    this.controller,
    this.scaleStateController,
    this.basePosition,
    this.scaleStateCycle,
    this.onTapUp,
    this.onTapDown,
    this.onLongPress,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.gestureDetectorBehavior,
    this.tightMode,
    this.filterQuality,
    this.disableGestures,
    this.disableDoubleTap,
    this.errorBuilder,
    this.childWrapper,
  })  : child = null,
        childSize = null,
        assert(imageProvider != null);

  PhotoViewGalleryPageOptions.customChild({
    this.pageKey,
    this.options,
    required this.child,
    this.semanticLabel,
    this.childSize,
    this.heroAttributes,
    this.minScale,
    this.maxScale,
    this.strictScale,
    this.initialScale,
    this.controller,
    this.scaleStateController,
    this.basePosition,
    this.scaleStateCycle,
    this.onTapUp,
    this.onTapDown,
    this.onLongPress,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.gestureDetectorBehavior,
    this.tightMode,
    this.filterQuality,
    this.disableGestures,
    this.disableDoubleTap,
    this.childWrapper,
  })  : errorBuilder = null,
        imageProvider = null;

  /// Mirror to [PhotoView.imageProvider]
  final ImageProvider? imageProvider;
  final Key? pageKey;
  final PhotoViewOptions? options;

  /// Mirror to [PhotoView.heroAttributes]
  final PhotoViewHeroAttributes? heroAttributes;

  /// Mirror to [PhotoView.semanticLabel]
  final String? semanticLabel;

  /// Mirror to [PhotoView.minScale]
  final PhotoViewScale? minScale;

  /// Mirror to [PhotoView.maxScale]
  final PhotoViewScale? maxScale;
  final bool? strictScale;

  /// Mirror to [PhotoView.initialScale]
  final PhotoViewScale? initialScale;

  /// Mirror to [PhotoView.controller]
  final PhotoViewController? controller;

  /// Mirror to [PhotoView.scaleStateController]
  final PhotoViewScaleStateController? scaleStateController;

  /// Mirror to [PhotoView.basePosition]
  final Alignment? basePosition;

  /// Mirror to [PhotoView.child]
  final Widget? child;

  /// Mirror to [PhotoView.childSize]
  final Size? childSize;

  /// Mirror to [PhotoView.scaleStateCycle]
  final ScaleStateCycle? scaleStateCycle;

  /// Mirror to [PhotoView.onTapUp]
  final PhotoViewImageTapUpCallback? onTapUp;

  /// Mirror to [PhotoView.onTapDown]
  final PhotoViewImageTapDownCallback? onTapDown;

  /// Mirror to [PhotoView.onLongPress]
  final PhotoViewImageLongPressCallback? onLongPress;

  /// Mirror to [PhotoView.onScaleStart]
  final PhotoViewImageScaleStartCallback? onScaleStart;

  /// Mirror to [PhotoView.onScaleUpdate]
  final PhotoViewImageScaleUpdateCallback? onScaleUpdate;

  /// Mirror to [PhotoView.onScaleEnd]
  final PhotoViewImageScaleEndCallback? onScaleEnd;

  /// Mirror to [PhotoView.gestureDetectorBehavior]
  final HitTestBehavior? gestureDetectorBehavior;

  /// Mirror to [PhotoView.tightMode]
  final bool? tightMode;

  /// Mirror to [PhotoView.disableGestures]
  final bool? disableGestures;

  /// Mirror to [PhotoView.disableDoubleTap]
  final bool? disableDoubleTap;

  /// Quality levels for image filters.
  final FilterQuality? filterQuality;

  /// Mirror to [PhotoView.errorBuilder]
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Wraps a page widget after the internal ClipRect is applied.
  final PhotoViewGalleryChildWrapper? childWrapper;
}
