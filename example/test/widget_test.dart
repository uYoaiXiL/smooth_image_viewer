import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smooth_image_viewer_example/main.dart';

void main() {
  testWidgets('opens and closes a gallery preview', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Gallery · Thumbnails & preloading'), findsOneWidget);

    await tester.tap(
      find
          .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsOneWidget);

    await tester.dragFrom(const Offset(700, 300), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 6'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsNothing);
    expect(find.text('Gallery · Thumbnails & preloading'), findsOneWidget);
  });

  testWidgets('custom overlay follows paging and closes with its own button', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('overlay-preview-0'));
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    final firstSize = tester.getSize(entry);
    for (var index = 1; index < 3; index++) {
      final size = tester.getSize(
        find.byKey(ValueKey('overlay-preview-$index')),
      );
      expect(size.width, closeTo(firstSize.width, 0.01));
      expect(size.height, closeTo(firstSize.height, 0.01));
    }
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('Custom title · Image 1'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.dragFrom(const Offset(700, 200), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('Custom title · Image 2'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.text('Close preview'));
    await tester.pumpAndSettle();
    expect(find.text('Custom title · Image 2'), findsNothing);
    expect(entry, findsOneWidget);
  });
}
