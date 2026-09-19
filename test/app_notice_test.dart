import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodia/widgets/app_notice.dart';

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return ctx;
}

void main() {
  testWidgets('başlık, mesaj ve aksiyon gösterilir; aksiyon çalışır', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    var tapped = false;
    AppNotice.show(
      context,
      'Hazır olduğunda haber vereceğiz.',
      title: 'Remix hazırlanıyor',
      type: NoticeType.success,
      actionLabel: 'Görüntüle',
      onAction: () => tapped = true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Remix hazırlanıyor'), findsOneWidget);
    expect(find.text('Hazır olduğunda haber vereceğiz.'), findsOneWidget);
    await tester.tap(find.text('Görüntüle'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    // Aksiyondan sonra bildirim kapanır.
    expect(find.text('Remix hazırlanıyor'), findsNothing);
  });

  testWidgets('yeni bildirim öncekinin yerini alır', (tester) async {
    final context = await _pumpHost(tester);
    AppNotice.show(context, 'Birinci', type: NoticeType.info);
    await tester.pump();
    AppNotice.show(context, 'İkinci', type: NoticeType.error);
    await tester.pumpAndSettle();
    expect(find.text('Birinci'), findsNothing);
    expect(find.text('İkinci'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
