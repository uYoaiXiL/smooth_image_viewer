import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_image_viewer/smooth_image_viewer.dart';

final _image = MemoryImage(
  Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1f,
    0x15,
    0xc4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9c,
    0x63,
    0xf8,
    0xcf,
    0xc0,
    0xf0,
    0x1f,
    0x00,
    0x05,
    0x00,
    0x01,
    0xff,
    0x89,
    0x99,
    0x3d,
    0x1d,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4e,
    0x44,
    0xae,
    0x42,
    0x60,
    0x82,
  ]),
);

void main() {
  testWidgets('a horizontal gesture cannot turn into pull-down dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(images: [_image, _image]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(650, 180));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 250));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('near-diagonal drags do not dismiss the preview', (tester) async {
    await tester.pumpWidget(_TestApp(images: [_image, _image]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(200, 180), const Offset(180, 220));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets(
    'pull-down remains on the same page when the finger turns sideways',
    (tester) async {
      await tester.pumpWidget(_TestApp(images: [_image, _image]));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(700, 200));
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      await gesture.moveBy(const Offset(-650, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
    },
  );

  testWidgets('a second finger cancels dismissal until all fingers lift', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(images: [_image, _image]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final first = await tester.startGesture(const Offset(250, 150), pointer: 1);
    await first.moveBy(const Offset(0, 150));
    await tester.pump();
    final second = await tester.startGesture(
      const Offset(400, 300),
      pointer: 2,
    );
    await tester.pumpAndSettle();
    await second.up();
    await first.moveBy(const Offset(0, 150));
    await tester.pump();
    await first.up();
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.dragFrom(const Offset(700, 250), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  for (final releaseDelay in [20, 400]) {
    testWidgets(
      'closing with a held pointer released after $releaseDelay ms does not pop twice',
      (tester) async {
        await tester.pumpWidget(_TestApp(images: [_image]));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          const Offset(200, 180),
          pointer: 1,
        );
        await gesture.moveBy(const Offset(0, 160));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.close), pointer: 2);
        await tester.pump(Duration(milliseconds: releaseDelay));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('open'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'rapid paging and closing during double-tap zoom stay consistent',
    (tester) async {
      await tester.pumpWidget(_TestApp(images: List.filled(5, _image)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.flingFrom(
          const Offset(700, 250),
          const Offset(-500, 0),
          1600,
        );
        await tester.pump(const Duration(milliseconds: 35));
      }
      await tester.pumpAndSettle();
      final page = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;
      expect(page, closeTo(page.roundToDouble(), 0.001));
      expect(find.text('${page.round() + 1} / 5'), findsOneWidget);
      await tester.tapAt(const Offset(300, 300));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(const Offset(300, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('open'), findsOneWidget);
    },
  );

  testWidgets(
    'pinch and remaining-finger pan never dismiss, then paging recovers',
    (tester) async {
      await tester.pumpWidget(_TestApp(images: [_image, _image]));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final first = await tester.startGesture(
        const Offset(300, 250),
        pointer: 1,
      );
      final second = await tester.startGesture(
        const Offset(500, 250),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(-60, 0));
      await second.moveBy(const Offset(60, 0));
      await tester.pump();
      await first.moveBy(const Offset(-60, 0));
      await second.moveBy(const Offset(60, 0));
      await tester.pump();
      final transform = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
          .transformationController!;
      expect(transform.value.getMaxScaleOnAxis(), greaterThan(1.01));
      await first.up();
      await second.moveBy(const Offset(0, 220));
      await tester.pump();
      await second.up();
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tapAt(const Offset(300, 300));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(const Offset(300, 300));
      await tester.pumpAndSettle();
      expect(transform.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
      await tester.dragFrom(const Offset(700, 250), const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'pinch arriving during a page drag cancels paging without leaving a partial page',
    (tester) async {
      await tester.pumpWidget(_TestApp(images: [_image, _image]));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final first = await tester.startGesture(
        const Offset(650, 250),
        pointer: 1,
      );
      await first.moveBy(const Offset(-25, 0));
      await tester.pump();
      await first.moveBy(const Offset(-180, 0));
      await tester.pump();
      final second = await tester.startGesture(
        const Offset(200, 250),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(-100, 0));
      await second.moveBy(const Offset(0, 80));
      await tester.pump();
      await first.cancel();
      await second.up();
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        0,
      );
      await tester.dragFrom(const Offset(700, 250), const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets('closing during zoom also works with exit Hero disabled', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(images: [_image], enableExitHero: false));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('adjacent preloading is disabled by default', (tester) async {
    final loads = <int>[];
    await tester.pumpWidget(
      _TestApp(
        images: [
          _ControlledImage(0, loads),
          _image,
          _ControlledImage(2, loads),
        ],
        initialIndex: 1,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(loads, isEmpty);
  });

  testWidgets('preloads only immediate neighbors, one request at a time', (
    tester,
  ) async {
    final loads = <int>[];
    final previous = _ControlledImage(1, loads);
    final next = _ControlledImage(3, loads);
    await tester.pumpWidget(
      _TestApp(
        images: [
          _ControlledImage(0, loads),
          previous,
          _image,
          next,
          _ControlledImage(4, loads),
        ],
        initialIndex: 2,
        preloadAdjacentImages: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(loads, [3]);
    final decoded = (await tester.runAsync(
      () => decodeImageFromList(_image.bytes),
    ))!;
    addTearDown(decoded.dispose);
    next.result.complete(ImageInfo(image: decoded.clone()));
    await tester.pumpAndSettle();
    expect(loads, [3, 1]);
    previous.result.complete(ImageInfo(image: decoded.clone()));
    await tester.pumpAndSettle();
    expect(loads, [3, 1]);
  });

  testWidgets('skips obsolete neighbors after paging during preload', (
    tester,
  ) async {
    final loads = <int>[];
    final loading = _ControlledImage(3, loads);
    final newNext = _ControlledImage(5, loads);
    await tester.pumpWidget(
      _TestApp(
        images: [
          _image,
          _ControlledImage(1, loads),
          _image,
          loading,
          _image,
          newNext,
        ],
        initialIndex: 2,
        preloadAdjacentImages: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(loads, [3]);
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(4);
    await tester.pumpAndSettle();
    final decoded = (await tester.runAsync(
      () => decodeImageFromList(_image.bytes),
    ))!;
    addTearDown(decoded.dispose);
    loading.result.complete(ImageInfo(image: decoded.clone()));
    await tester.pumpAndSettle();
    expect(loads, [3, 5]);
    newNext.result.complete(ImageInfo(image: decoded.clone()));
    await tester.pumpAndSettle();
  });

  testWidgets('preload failure is silent and closing skips remaining work', (
    tester,
  ) async {
    final loads = <int>[];
    final previous = _ControlledImage(0, loads);
    final next = _ControlledImage(2, loads);
    await tester.pumpWidget(
      _TestApp(
        images: [previous, _image, next],
        initialIndex: 1,
        preloadAdjacentImages: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(loads, [2]);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    next.result.completeError(StateError('preload failed'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(loads, [2]);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('close and page indicator expose accessible descriptions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_TestApp(images: [_image, _image]));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close'), findsOneWidget);
      final close = tester.getSemantics(find.byType(IconButton));
      expect(close.getSemanticsData().tooltip, 'Close');
      expect(close.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        close.getSemanticsData().flagsCollection.isFocused,
        ui.Tristate.isTrue,
      );
      final page = tester.getSemantics(find.bySemanticsLabel('Image 1 of 2'));
      expect(page.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      await tester.dragFrom(const Offset(700, 300), const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Image 2 of 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Image 1 of 2'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('keyboard traverses overlay controls and activates close', (
    tester,
  ) async {
    final overlayFocus = FocusNode();
    addTearDown(overlayFocus.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        images: [_image],
        overlayBuilder: (context, index) => Align(
          alignment: Alignment.bottomCenter,
          child: TextButton(
            focusNode: overlayFocus,
            onPressed: () => taps++,
            child: const Text('custom action'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.byIcon(Icons.close))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(overlayFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  for (final direction in TextDirection.values) {
    testWidgets('large text header fits a narrow $direction viewport', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.binding.setSurfaceSize(const Size(200, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _TestApp(
            images: List.filled(30, _image),
            initialIndex: 29,
            textScale: 3,
            direction: direction,
            pageIndicatorSemanticLabelBuilder: (index, total) =>
                '第 ${index + 1} 张图片，共 $total 张',
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('第 30 张图片，共 30 张'), findsOneWidget);
        final label = tester.getRect(find.text('30 / 30'));
        final close = tester.getRect(find.byType(IconButton));
        expect(label.overlaps(close), isFalse);
        expect(label.left, greaterThanOrEqualTo(0));
        expect(label.right, lessThanOrEqualTo(200));
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.text('open'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('overlay follows the page without blocking $kind paging', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        _TestApp(
          images: [_image, _image, _image],
          initialIndex: 1,
          overlayBuilder: (context, index) => Align(
            alignment: Alignment.bottomCenter,
            child: TextButton(
              onPressed: () => selected.add(index),
              child: Text('action $index'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('action 1'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.dragFrom(
        const Offset(700, 300),
        const Offset(-650, 0),
        kind: kind,
      );
      await tester.pumpAndSettle();
      expect(find.text('action 2'), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.text('action 2'));
      expect(selected, [2]);

      await tester.dragFrom(
        const Offset(100, 300),
        const Offset(650, 0),
        kind: kind,
      );
      await tester.pumpAndSettle();
      expect(find.text('action 1'), findsOneWidget);
    });
  }

  testWidgets('overlay interactions do not dismiss or page the image', (
    tester,
  ) async {
    var taps = 0;
    const controlKey = ValueKey('overlay control');
    await tester.pumpWidget(
      _TestApp(
        images: [_image, _image],
        overlayBuilder: (context, index) => Center(
          child: GestureDetector(
            key: controlKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 200, height: 100),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(controlKey));
    expect(taps, 1);
    await tester.drag(find.byKey(controlKey), const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.drag(find.byKey(controlKey), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);

    // Unoccupied overlay space still lets the image handle dismissal.
    await tester.dragFrom(const Offset(100, 200), const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('overlay context can close the preview route', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        images: [_image],
        overlayBuilder: (context, index) => Align(
          alignment: Alignment.bottomCenter,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('custom close'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom close'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('overlay stays in place and fades with pull-down dismissal', (
    tester,
  ) async {
    const overlayKey = ValueKey('overlay label');
    await tester.pumpWidget(
      _TestApp(
        images: [_image],
        overlayBuilder: (context, index) => const Align(
          alignment: Alignment.bottomCenter,
          child: Text('caption', key: overlayKey),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final originalPosition = tester.getTopLeft(find.byKey(overlayKey));
    final gesture = await tester.startGesture(const Offset(200, 200));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    final opacityFinder = find.ancestor(
      of: find.byKey(overlayKey),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(opacityFinder).opacity, closeTo(0.8, 0.01));
    expect(tester.getTopLeft(find.byKey(overlayKey)), originalPosition);

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacityFinder).opacity, 1);
  });

  testWidgets('fits a portrait image within the viewport after resizing', (
    tester,
  ) async {
    final portrait = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 200, 400),
        Paint()..color = Colors.red,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 400);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return MemoryImage(bytes!.buffer.asUint8List());
    });
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 600));
    await tester.pumpWidget(_TestApp(images: [portrait!]));
    await tester.runAsync(
      () => precacheImage(portrait, tester.element(find.text('open'))),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    for (final viewport in [
      const Size(1200, 600),
      const Size(400, 800),
      const Size(1200, 400),
    ]) {
      await tester.binding.setSurfaceSize(viewport);
      await tester.pumpAndSettle();
      final expectedSize = applyBoxFit(
        BoxFit.contain,
        const Size(200, 400),
        viewport,
      ).destination;
      // Check both the static Hero layer and the interactive image, including
      // ancestor transforms, so a clipped or stretched image cannot pass.
      final images = find.byType(RawImage);
      expect(images, findsNWidgets(2));
      for (final element in images.evaluate()) {
        final box = element.renderObject! as RenderBox;
        final topLeft = box.localToGlobal(Offset.zero);
        final bottomRight = box.localToGlobal(
          box.size.bottomRight(Offset.zero),
        );
        final bounds = Rect.fromPoints(topLeft, bottomRight);
        expect(bounds.width, closeTo(expectedSize.width, 0.01));
        expect(bounds.height, closeTo(expectedSize.height, 0.01));
        expect(bounds.center.dx, closeTo(viewport.width / 2, 0.01));
        expect(bounds.center.dy, closeTo(viewport.height / 2, 0.01));
      }
    }
  });

  test('exposes the supported hero shapes', () {
    expect(const ImageViewerShape.rectangle(), isA<ImageViewerRectangle>());
    expect(const ImageViewerShape.circle(), isA<ImageViewerCircle>());
    expect(const ImageViewerShape.rounded(12), isA<ImageViewerRounded>());
    expect(
      const ImageViewerShape.roundedCorners(
        BorderRadius.only(topLeft: Radius.circular(12)),
      ),
      isA<ImageViewerRoundedCorners>(),
    );
  });

  testWidgets('pages horizontally before zooming', (tester) async {
    await tester.pumpWidget(
      _TestApp(images: <ImageProvider<Object>>[_image, _image]),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(700, 400), const Offset(-650, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('pages in both directions with a mouse', (tester) async {
    await tester.pumpWidget(
      _TestApp(images: <ImageProvider<Object>>[_image, _image]),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(
      const Offset(700, 400),
      const Offset(-650, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.dragFrom(
      const Offset(100, 400),
      const Offset(650, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('mouse pans while zoomed and pages after zooming out', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(images: <ImageProvider<Object>>[_image, _image]),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Future<void> doubleClick() async {
      await tester.tapAt(const Offset(400, 300), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(const Offset(400, 300), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
    }

    await doubleClick();
    final transform = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
        .transformationController!;
    expect(transform.value.getMaxScaleOnAxis(), closeTo(2, 0.01));
    final beforePan = transform.value.clone();

    await tester.dragFrom(
      const Offset(700, 400),
      const Offset(-650, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(transform.value, isNot(beforePan));

    await doubleClick();
    expect(transform.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
    await tester.dragFrom(
      const Offset(700, 400),
      const Offset(-650, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('dismisses after pulling down with a mouse', (tester) async {
    await tester.pumpWidget(_TestApp(images: <ImageProvider<Object>>[_image]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(
      const Offset(200, 300),
      const Offset(0, 250),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('keeps the current page when zooming after paging', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(images: <ImageProvider<Object>>[_image, _image]),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(700, 400), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('dismisses after pulling down', (tester) async {
    await tester.pumpWidget(_TestApp(images: <ImageProvider<Object>>[_image]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(200, 300), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.images,
    this.initialIndex = 0,
    this.overlayBuilder,
    this.preloadAdjacentImages = false,
    this.pageIndicatorSemanticLabelBuilder,
    this.textScale = 1,
    this.direction = TextDirection.ltr,
    this.enableExitHero = true,
  });
  final List<ImageProvider<Object>> images;
  final int initialIndex;
  final IndexedWidgetBuilder? overlayBuilder;
  final bool preloadAdjacentImages;
  final String Function(int, int)? pageIndicatorSemanticLabelBuilder;
  final double textScale;
  final TextDirection direction;
  final bool enableExitHero;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ImageViewerRoute.open(
                context,
                images: images,
                initialIndex: initialIndex,
                enableExitHero: enableExitHero,
                overlayBuilder: overlayBuilder,
                preloadAdjacentImages: preloadAdjacentImages,
                pageIndicatorSemanticLabelBuilder:
                    pageIndicatorSemanticLabelBuilder,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlledImage extends ImageProvider<_ControlledImage> {
  _ControlledImage(this.id, this.loads);

  final int id;
  final List<int> loads;
  final result = Completer<ImageInfo>();

  @override
  Future<_ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ControlledImage key,
    ImageDecoderCallback decode,
  ) {
    loads.add(id);
    return OneFrameImageStreamCompleter(result.future);
  }
}
