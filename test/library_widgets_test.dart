import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodia/widgets/library_list_item.dart';
import 'package:melodia/widgets/paged_list_section.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('PagedListSection: sayfa başına 4 satır, kaydırınca sonraki sayfa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PagedListSection(
          title: 'Şarkılarım',
          itemCount: 6,
          itemBuilder: (context, i) => Text('Şarkı $i'),
        ),
      ),
    );

    expect(find.text('Şarkılarım'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(find.text('Şarkı $i'), findsOneWidget);
    }
    expect(find.text('Şarkı 4'), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Şarkı 4'), findsOneWidget);
    expect(find.text('Şarkı 5'), findsOneWidget);
    expect(find.text('Şarkı 0'), findsNothing);
  });

  testWidgets('PagedListSection: tek sayfada nokta gösterilmez', (tester) async {
    await tester.pumpWidget(
      _host(
        PagedListSection(
          title: 'Videolarım',
          itemCount: 3,
          itemBuilder: (context, i) => Text('Klip $i'),
        ),
      ),
    );
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('LibraryListItem: başlık, etiket, bilgi ve menü', (tester) async {
    var tapped = false;
    var more = false;
    await tester.pumpWidget(
      _host(
        LibraryListItem(
          title: 'Gece Yolu',
          kind: LibraryItemKind.remix,
          kindLabel: 'Remix',
          metadata: '19 Eyl 2026 · Pop',
          onTap: () => tapped = true,
          onMore: () => more = true,
        ),
      ),
    );

    expect(find.text('Gece Yolu'), findsOneWidget);
    expect(find.text('Remix'), findsOneWidget);
    expect(find.text('19 Eyl 2026 · Pop'), findsOneWidget);

    await tester.tap(find.text('Gece Yolu'));
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    expect(tapped, isTrue);
    expect(more, isTrue);
  });
}
