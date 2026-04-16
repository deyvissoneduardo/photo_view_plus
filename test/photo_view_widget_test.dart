import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

    await tester.drag(find.byType(PhotoView), const Offset(40, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.position, isNot(Offset.zero));
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
}
