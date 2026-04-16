import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view_plus/photo_view_plus.dart';
import 'package:photo_view_plus/photo_view_plus_gallery.dart';

void main() {
  testWidgets('rebinds scale state controller when widget updates',
      (WidgetTester tester) async {
    final firstController = PhotoViewScaleStateController();
    final secondController = PhotoViewScaleStateController();
    final callbacks = <PhotoViewScaleState>[];

    Widget buildWidget(PhotoViewScaleStateController controller) {
      return MaterialApp(
        home: PhotoView.customChild(
          scaleStateController: controller,
          scaleStateChangedCallback: callbacks.add,
          initialScale: const PhotoViewScale.fixed(1.0),
          childSize: const Size(100, 100),
          child: const SizedBox(width: 100, height: 100),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(firstController));

    firstController.scaleState = PhotoViewScaleState.covering;
    await tester.pump();

    await tester.pumpWidget(buildWidget(secondController));

    firstController.scaleState = PhotoViewScaleState.originalSize;
    secondController.scaleState = PhotoViewScaleState.covering;
    await tester.pump();

    expect(
      callbacks,
      <PhotoViewScaleState>[
        PhotoViewScaleState.covering,
        PhotoViewScaleState.covering,
      ],
    );
  });

  testWidgets('PhotoViewOptions applies background and overlay builders',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(80, 80),
            options: PhotoViewOptions(
              backgroundBuilder: (context, child) => DecoratedBox(
                key: const Key('background'),
                decoration: const BoxDecoration(color: Colors.red),
                child: child,
              ),
              overlayBuilder: (context, details) => Align(
                alignment: Alignment.topRight,
                child: Text(
                  details.scaleState.name,
                  key: const Key('overlay'),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('background')), findsOneWidget);
    expect(find.byKey(const Key('overlay')), findsOneWidget);
  });

  testWidgets('PhotoViewOptions applies child wrapper',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(80, 80),
            options: PhotoViewOptions(
              childWrapper: (context, child) => DecoratedBox(
                key: const Key('child-wrapper'),
                decoration: const BoxDecoration(color: Colors.blue),
                child: child,
              ),
            ),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('child-wrapper')), findsOneWidget);
  });

  testWidgets('disableDoubleTap keeps scale unchanged',
      (WidgetTester tester) async {
    final controller = PhotoViewController(initialScale: 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            controller: controller,
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(80, 80),
            options: const PhotoViewOptions(disableDoubleTap: true),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PhotoView), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(PhotoView), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.scale, 1.0);
  });

  testWidgets('long press callback is triggered', (WidgetTester tester) async {
    var longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(80, 80),
            onLongPress: (context, controllerValue) {
              longPressed = true;
            },
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(PhotoView), warnIfMissed: false);
    await tester.pump();

    expect(longPressed, isTrue);
  });

  testWidgets('scale start and update callbacks are triggered',
      (WidgetTester tester) async {
    var scaleStartCalled = false;
    var scaleUpdateCalled = false;
    PhotoViewControllerValue? startValue;
    PhotoViewControllerValue? updateValue;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(120, 120),
            onScaleStart: (context, details, controllerValue) {
              scaleStartCalled = true;
              startValue = controllerValue;
            },
            onScaleUpdate: (context, details, controllerValue) {
              scaleUpdateCalled = true;
              updateValue = controllerValue;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(PhotoView),
      const Offset(24, 12),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(scaleStartCalled, isTrue);
    expect(scaleUpdateCalled, isTrue);
    expect(startValue, isNotNull);
    expect(updateValue, isNotNull);
    expect(updateValue!.scale, isNotNull);
  });

  testWidgets('enablePanAlways allows dragging small children',
      (WidgetTester tester) async {
    final controller = PhotoViewController();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            controller: controller,
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(80, 80),
            options: const PhotoViewOptions(enablePanAlways: true),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(PhotoView),
      const Offset(40, 20),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.position, isNot(Offset.zero));
  });

  testWidgets('mouse wheel scroll pans content', (WidgetTester tester) async {
    final controller = PhotoViewController(initialScale: 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            controller: controller,
            initialScale: const PhotoViewScale.fixed(1.0),
            childSize: const Size(80, 80),
            options: const PhotoViewOptions(enablePanAlways: true),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    final center =
        tester.getCenter(find.byType(PhotoView), warnIfMissed: false);
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, -24),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    expect(controller.position, isNot(Offset.zero));
  });

  testWidgets('trackpad pan zoom update changes scale and position',
      (WidgetTester tester) async {
    final controller = PhotoViewController(initialScale: 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            controller: controller,
            initialScale: const PhotoViewScale.fixed(1.0),
            minScale: const PhotoViewScale.fixed(0.5),
            maxScale: const PhotoViewScale.fixed(4.0),
            childSize: const Size(80, 80),
            options: const PhotoViewOptions(enablePanAlways: true),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    final center =
        tester.getCenter(find.byType(PhotoView), warnIfMissed: false);
    tester.binding.handlePointerEvent(
      PointerPanZoomStartEvent(
        position: center,
      ),
    );
    tester.binding.handlePointerEvent(
      PointerPanZoomUpdateEvent(
        position: center,
        pan: const Offset(18, 10),
        panDelta: const Offset(18, 10),
        scale: 1.2,
      ),
    );
    tester.binding.handlePointerEvent(
      PointerPanZoomEndEvent(
        position: center,
      ),
    );
    await tester.pump();

    expect(controller.scale, isNotNull);
    expect(controller.scale, greaterThan(1.0));
    expect(controller.position, isNot(Offset.zero));
  });

  testWidgets('ctrl scroll changes scale around cursor',
      (WidgetTester tester) async {
    final controller = PhotoViewController(initialScale: 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            controller: controller,
            initialScale: const PhotoViewScale.fixed(1.0),
            minScale: const PhotoViewScale.fixed(0.5),
            maxScale: const PhotoViewScale.fixed(4.0),
            childSize: const Size(80, 80),
            options: const PhotoViewOptions(enablePanAlways: true),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    final center =
        tester.getCenter(find.byType(PhotoView), warnIfMissed: false);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, -24),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(controller.scale, isNotNull);
    expect(controller.scale, greaterThan(1.0));
  });

  testWidgets('interactive PhotoView builds mouse region for cursor handling',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: PhotoView.customChild(
            initialScale: PhotoViewScale.fixed(1.0),
            childSize: Size(80, 80),
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byType(MouseRegion), findsAtLeastNWidgets(1));
  });

  testWidgets('gallery preloads and caches page options',
      (WidgetTester tester) async {
    final builtIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoViewGallery.builder(
          itemCount: 5,
          options: const PhotoViewGalleryOptions(preloadPagesCount: 2),
          builder: (context, index) {
            builtIndexes.add(index);
            return PhotoViewGalleryPageOptions.customChild(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Text('$index', textDirection: TextDirection.ltr),
              ),
              childSize: const Size(80, 80),
              initialScale: const PhotoViewScale.fixed(1.0),
              pageKey: Key('page-$index'),
            );
          },
        ),
      ),
    );

    expect(builtIndexes.toSet(), containsAll(<int>[0, 1, 2]));
    expect(find.byKey(const Key('page-0')), findsOneWidget);
  });

  testWidgets('gallery childWrapper wraps each page',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoViewGallery.builder(
          itemCount: 1,
          options: PhotoViewGalleryOptions(
            childWrapper: (context, index, child) => DecoratedBox(
              key: const Key('gallery-wrapper'),
              decoration: const BoxDecoration(color: Colors.green),
              child: child,
            ),
          ),
          builder: (context, index) {
            return PhotoViewGalleryPageOptions.customChild(
              child: const SizedBox(width: 80, height: 80),
              childSize: const Size(80, 80),
              initialScale: const PhotoViewScale.fixed(1.0),
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('gallery-wrapper')), findsOneWidget);
  });

  testWidgets('gallery page disableDoubleTap overrides shared options',
      (WidgetTester tester) async {
    final controller = PhotoViewController(initialScale: 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoViewGallery.builder(
          itemCount: 1,
          options: const PhotoViewGalleryOptions(
            options: PhotoViewOptions(disableDoubleTap: false),
          ),
          builder: (context, index) {
            return PhotoViewGalleryPageOptions.customChild(
              controller: controller,
              child: const SizedBox(width: 80, height: 80),
              childSize: const Size(80, 80),
              initialScale: const PhotoViewScale.fixed(1.0),
              disableDoubleTap: true,
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(PhotoView), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(PhotoView), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.scale, 1.0);
  });

  testWidgets('error state keeps hero wrapper available',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: PhotoView(
            imageProvider: _FailingImageProvider(),
            heroAttributes: PhotoViewHeroAttributes(tag: 'broken-image'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(Hero), findsOneWidget);
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  const _FailingImageProvider();

  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_FailingImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(
        StateError('image load failed'),
        StackTrace.current,
      ),
    );
  }
}
