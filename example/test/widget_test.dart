import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smooth_image_viewer_example/main.dart';

void main() {
  testWidgets('opens and closes a gallery preview', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('多图预览 + 缩略图首帧'), findsOneWidget);

    await tester.tap(
      find
          .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsNothing);
    expect(find.text('多图预览 + 缩略图首帧'), findsOneWidget);
  });
}
