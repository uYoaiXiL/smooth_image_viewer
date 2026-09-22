import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    0x08,
    0xd7,
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
  const _TestApp({required this.images});
  final List<ImageProvider<Object>> images;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ImageViewerRoute.open(
                context,
                images: images,
                initialIndex: 0,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}
