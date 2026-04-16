# Flutter Photo View

[![Tests status](https://img.shields.io/github/actions/workflow/status/bluefireteam/photo_view/ci.yml?branch=master)](https://github.com/bluefireteam/photo_view/actions)
[![Pub](https://img.shields.io/pub/v/photo_view.svg?style=popout)](https://pub.dartlang.org/packages/photo_view)

`photo_view` provides a gesture-aware zoomable widget for images and custom
content. This fork is updated for modern Flutter, adds a stronger typed API,
and exposes new configuration points for overlays, gallery behavior, and
interaction policies.

## Requirements

- Flutter `>=3.14.5`
- Dart `>=3.1.0`

```yaml
dependencies:
  photo_view: ^1.1.0
```

## What's New

- Flutter 3.14.5+ and Dart 3.1+ baseline
- typed scale API with `PhotoViewScale.fixed(...)`
- new `PhotoViewOptions` for consolidated widget configuration
- new `PhotoViewGalleryOptions` for gallery preload and retention
- richer customization with `overlayBuilder`, `backgroundBuilder`,
  `loadingStateBuilder`, and `errorStateBuilder`
- `childWrapper` for wrapping the final rendered widget in single view or gallery
- new gesture callbacks: `onLongPress`, `onScaleStart`, and `onScaleUpdate`
- `disableDoubleTap` to keep pan and pinch active while disabling the internal double tap zoom cycle
- `PhotoViewComputedScale.containedNoScaleUp` for contain-fit without enlarging smaller assets
- injectable `PhotoViewInteractionPolicy` for clamp, gesture-end, and dynamic
  filter quality rules
- gallery page option caching and configurable image preloading
- desktop/web pointer support with wheel pan, `Ctrl+scroll` zoom, trackpad pan/zoom, and contextual cursors
- internal architecture split into `ui/`, `domain/`, `data/`, `core/`, and
  `shared/`

## Basic Usage

```dart
import 'package:photo_view/photo_view.dart';

PhotoView(
  imageProvider: const AssetImage('assets/large-image.jpg'),
  initialScale: PhotoViewScale.contained,
  minScale: PhotoViewScale.contained * 0.8,
  maxScale: PhotoViewScale.covered * 1.8,
);
```

Use `PhotoView.customChild` to zoom any widget:

```dart
PhotoView.customChild(
  child: const FlutterLogo(size: 200),
  childSize: const Size(200, 200),
  initialScale: const PhotoViewScale.fixed(1),
);
```

## Configuration with `PhotoViewOptions`

Prefer `options` for new integrations. Legacy constructor parameters still
work and override values from `options` when both are provided.

```dart
PhotoView(
  imageProvider: const AssetImage('assets/large-image.jpg'),
  options: PhotoViewOptions(
    filterQuality: FilterQuality.high,
    strictScale: true,
    overlayBuilder: (context, details) => Align(
      alignment: Alignment.bottomRight,
      child: Text(details.scaleState.name),
    ),
  ),
);
```

`PhotoViewOptions` supports:

- `backgroundDecoration`
- `wantKeepAlive`
- `customSize`
- `gestureDetectorBehavior`
- `tightMode`
- `filterQuality`
- `disableGestures`
- `disableDoubleTap`
- `enablePanAlways`
- `strictScale`
- `interactionPolicy`
- `overlayBuilder`
- `backgroundBuilder`
- `loadingStateBuilder`
- `errorStateBuilder`
- `childWrapper`

## New Interaction Hooks

```dart
PhotoView(
  imageProvider: provider,
  options: const PhotoViewOptions(disableDoubleTap: true),
  onLongPress: (context, value) {
    debugPrint('long press at scale ${value.scale}');
  },
  onScaleStart: (context, details, value) {},
  onScaleUpdate: (context, details, value) {},
);
```

For desktop and web, mouse wheel pan, `Ctrl + scroll` zoom-to-cursor, and
trackpad pan/zoom now work out of the box.

## Gallery

```dart
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

PhotoViewGallery.builder(
  itemCount: galleryItems.length,
  options: const PhotoViewGalleryOptions(
    preloadPagesCount: 2,
    pageRetentionPolicy: PhotoViewGalleryPageRetentionPolicy.keepAlive,
  ),
  builder: (context, index) {
    final item = galleryItems[index];
    return PhotoViewGalleryPageOptions(
      imageProvider: AssetImage(item.image),
      initialScale: PhotoViewScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: item.id),
      options: PhotoViewOptions(
        overlayBuilder: (_, details) => Align(
          alignment: Alignment.topRight,
          child: Text(details.scaleState.name),
        ),
      ),
    );
  },
);
```

`PhotoViewGalleryOptions` adds:

- `preloadPagesCount`
- `pageRetentionPolicy`
- `scrollPhysics`
- `scrollDirection`
- `allowImplicitScrolling`
- `pageSnapping`
- shared `options` for all pages
- shared `childWrapper` for all pages

`PhotoViewGalleryPageOptions` now also accepts:

- `pageKey`
- `options`
- `childWrapper`
- `disableDoubleTap`
- `strictScale`
- `onLongPress`
- `onScaleStart`
- `onScaleUpdate`

## Wrapping The Final Child

Use `childWrapper` when you need interactive UI around the final rendered
result instead of a passive overlay:

```dart
PhotoViewGallery.builder(
  itemCount: items.length,
  options: PhotoViewGalleryOptions(
    childWrapper: (context, index, child) {
      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ),
        ],
      );
    },
  ),
  builder: (context, index) => PhotoViewGalleryPageOptions(
    imageProvider: AssetImage(items[index]),
  ),
);
```

## Interaction Policies

`PhotoViewInteractionPolicy` lets you customize interaction rules without
forking the widget.

```dart
const policy = PhotoViewInteractionPolicy(
  filterQuality: defaultFilterQualityProvider,
  clampPosition: defaultClampPositionPolicy,
  onGestureEnd: defaultGestureEndPolicy,
);
```

You can replace:

- position clamp behavior
- post-gesture return/fling behavior
- filter quality while gestures are active

## Migration Guide

### 1. Update SDK constraints

Use Flutter `>=3.14.5` and Dart `>=3.1.0`.

### 2. Replace `dynamic` scale values

Old:

```dart
PhotoView(
  minScale: 0.8,
  maxScale: 3.0,
  initialScale: 1.0,
);
```

New:

```dart
PhotoView(
  minScale: const PhotoViewScale.fixed(0.8),
  maxScale: const PhotoViewScale.fixed(3.0),
  initialScale: const PhotoViewScale.fixed(1.0),
);
```

Viewport-relative scales still work:

```dart
PhotoView(
  minScale: PhotoViewComputedScale.contained * 0.8,
  maxScale: PhotoViewComputedScale.covered * 1.8,
  initialScale: PhotoViewScale.contained,
);
```

There is also a no-upscale fit mode:

```dart
PhotoView(
  imageProvider: provider,
  initialScale: PhotoViewComputedScale.containedNoScaleUp,
);
```

### 3. Move optional flags into `options`

Old:

```dart
PhotoView(
  imageProvider: provider,
  filterQuality: FilterQuality.high,
  strictScale: true,
  enablePanAlways: false,
);
```

New:

```dart
PhotoView(
  imageProvider: provider,
  options: const PhotoViewOptions(
    filterQuality: FilterQuality.high,
    strictScale: true,
    enablePanAlways: false,
  ),
);
```

### 4. Migrate gallery setup

Old gallery-wide state retention relied on `wantKeepAlive`.

New code can use:

```dart
const PhotoViewGalleryOptions(
  preloadPagesCount: 2,
  pageRetentionPolicy: PhotoViewGalleryPageRetentionPolicy.keepAlive,
)
```

### 5. Adopt rich loading and error builders

Old:

```dart
loadingBuilder: (context, event) => const CircularProgressIndicator(),
errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
```

New:

```dart
options: PhotoViewOptions(
  loadingStateBuilder: (context, details) {
    return CircularProgressIndicator(
      value: details.progress == null
          ? null
          : details.progress!.cumulativeBytesLoaded /
              details.progress!.expectedTotalBytes!,
    );
  },
  errorStateBuilder: (context, details) => Text('${details.error}'),
),
```

### Breaking Changes Summary

- Flutter and Dart minimum versions increased
- scale inputs are now typed as `PhotoViewScale`
- new options objects are the preferred configuration path
- gallery adds preload/retention concepts beyond `wantKeepAlive`

## Controllers

`PhotoViewController` exposes viewport state updates.  
`PhotoViewScaleStateController` exposes scale-state transitions.

Both follow the standard Flutter controller lifecycle: create externally when
needed, listen to their streams, and dispose them when no longer used.

## Internal Architecture

The package internals are organized as:

- `lib/src/ui/`: widgets, view models, coordinators
- `lib/src/domain/`: immutable models and interaction rules
- `lib/src/data/`: image stream resolution
- `lib/src/core/`: low-level rendering and layout primitives
- `lib/src/shared/`: small reusable foundation utilities

This matters mainly for contributors. Public integrations should keep using the
exports from `lib/photo_view.dart` and `lib/photo_view_gallery.dart`.

## Validation

The current package state is validated with:

- `flutter analyze`
- `flutter test`

The automated suite currently covers:

- controller and scale-state controller behavior
- typed scale resolution, including `PhotoViewComputedScale.containedNoScaleUp`
- `PhotoViewOptions` hooks such as `overlayBuilder` and `childWrapper`
- gesture callbacks: `onLongPress`, `onScaleStart`, and `onScaleUpdate`
- `disableDoubleTap` behavior in single view and gallery page overrides
- `enablePanAlways` drag behavior
- gallery preload, page-option caching, and `childWrapper`
- desktop/web pointer interactions:
  `PointerScrollEvent` pan, `Ctrl + scroll` zoom, and trackpad
  `PointerPanZoomUpdateEvent`
- error-state rendering with `heroAttributes` still keeping a `Hero` in the tree

## Example App

Run the example locally:

```bash
flutter run -d <device> example/lib/main.dart
```

The gallery example demonstrates preload, retention, and overlay support.
