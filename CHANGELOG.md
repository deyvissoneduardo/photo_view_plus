<a name="1.1.1"></a>
# [1.1.0](https://github.com/deyvissoneduardo/photo_view_plus/releases/tag/1.1.1) - 24 Apr 2026

- docs

[Changes][1.1.1]

<a name="1.1.0"></a>
# [1.1.0](https://github.com/deyvissoneduardo/photo_view_plus/releases/tag/1.1.0) - 16 Apr 2026

## Added
- `disableDoubleTap` in `PhotoViewOptions` to disable only the internal double-tap scale cycle
- new gesture callbacks: `onLongPress`, `onScaleStart`, and `onScaleUpdate`
- `childWrapper` in `PhotoViewOptions`, `PhotoViewGalleryOptions`, and `PhotoViewGalleryPageOptions`
- `PhotoViewComputedScale.containedNoScaleUp` for contained fit without stretching smaller content
- desktop/web pointer support with mouse-wheel pan, `Ctrl + scroll` zoom-to-cursor, trackpad pan/zoom, and contextual mouse cursors

## Changed
- updated README, README-pt, and the gallery example to cover the new interaction and wrapping APIs
- expanded widget and scale test coverage for the new gestures, wrappers, and scale mode

## Fixed
- pinch + pan now keeps the touched content anchored correctly during simultaneous scale and translation
- image stream resolution now ignores stale callbacks more defensively and avoids null-related rebuild failures
- hero transitions remain more stable when the destination enters loading or error states

[Changes][1.1.0]

<a name="1.0.0"></a>
# [1.0.0](https://github.com/deyvissoneduardo/photo_view_plus/releases/tag/1.0.0) - 16 Apr 2026

## Added
- Typed scale API with `PhotoViewScale.fixed(...)` and `PhotoViewComputedScale.*`
- `PhotoViewOptions` and `PhotoViewGalleryOptions` for consolidated widget and gallery configuration
- `PhotoViewInteractionPolicy` for customizable clamp, gesture-end, and dynamic `filterQuality` behavior
- Rich customization hooks with `overlayBuilder`, `backgroundBuilder`, `loadingStateBuilder`, and `errorStateBuilder`
- Gallery page preloading, configurable page retention, and page option caching
- New transformation/layout test coverage and widget tests for key interactive flows

## Changed
- Raised the minimum supported SDKs to Flutter `>=3.14.5` and Dart `>=3.1.0`
- Reorganized internals into `ui/`, `domain/`, `data/`, `core/`, and `shared/`
- Updated README and example app to document and demonstrate the modernized API

## Fixed
- Rebound external controllers correctly when widgets update
- Hardened the image stream lifecycle to avoid stale listeners and null-related failures
- Preserved image frame state correctly in wrappers and aligned gallery/page interaction behavior with the new options model

## Breaking
- `minScale`, `maxScale`, and `initialScale` now use `PhotoViewScale` instead of loosely typed values
- The supported Flutter/Dart baseline now requires Flutter 3.14.5+ and Dart 3.1+

[Changes][1.0.0]
