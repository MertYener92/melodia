import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import 'package:melodia/models/song.dart';
import 'package:melodia/services/song_library.dart';
import 'package:melodia/widgets/player/remix_sheet.dart';

final _source = LibrarySong(
  song: Song(
    id: 'song-1',
    title: 'Sıcak Asfalt',
    prompt: '[Verse] ...',
    audioUrl: '',
    streamAudioUrl: '',
    imageUrl: '',
  ),
  genre: 'Pop',
  mood: 'Enerjik',
  createdAt: DateTime(2026),
);

Future<void> _pump(
  WidgetTester tester, {
  int? credits = 100,
  ValueChanged<RemixRequest>? onSubmit,
  VoidCallback? onBuyCredits,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: RemixSheet(
            source: _source,
            availableCredits: credits,
            onSubmit: onSubmit ?? (_) {},
            onBuyCredits: onBuyCredits,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('başlık, maliyet ve tarz çipleri görünür', (tester) async {
    await _pump(tester);
    expect(find.text('Sıcak Asfalt'), findsOneWidget);
    expect(find.text('$kRemixCreditCost'), findsOneWidget);
    expect(find.text('Akustik'), findsOneWidget);
    expect(find.text('Enstrümantal'), findsOneWidget);
  });

  testWidgets('tarz seçilmeden gönderilemez, çip seçince gönderilir', (
    tester,
  ) async {
    RemixRequest? sent;
    await _pump(tester, onSubmit: (r) => sent = r);

    await tester.tap(find.byTooltip('Remix oluştur'));
    await tester.pump();
    expect(sent, isNull);

    await tester.tap(find.text('Akustik'));
    await tester.tap(find.text('Rock'));
    await tester.pump();
    await tester.tap(find.byTooltip('Remix oluştur'));
    await tester.pump();

    expect(sent, isNotNull);
    expect(sent!.style, 'acoustic, rock');
    expect(sent!.styleLabel, 'Akustik · Rock');
    expect(sent!.instrumental, isFalse);
  });

  testWidgets('serbest metin ve enstrümantal tarife eklenir', (tester) async {
    RemixRequest? sent;
    await _pump(tester, onSubmit: (r) => sent = r);

    await tester.tap(find.text('Enstrümantal'));
    await tester.enterText(find.byType(TextField), 'yavaş tempo');
    await tester.pump();
    await tester.tap(find.byTooltip('Remix oluştur'));
    await tester.pump();

    expect(sent!.style, 'instrumental, yavaş tempo');
    expect(sent!.styleLabel, 'yavaş tempo');
    expect(sent!.instrumental, isTrue);
  });

  testWidgets('jeton yetmezse gönderilemez ve Kredi al görünür', (
    tester,
  ) async {
    RemixRequest? sent;
    var buyTapped = false;
    await _pump(
      tester,
      credits: kRemixCreditCost - 1,
      onSubmit: (r) => sent = r,
      onBuyCredits: () => buyTapped = true,
    );

    await tester.tap(find.text('Akustik'));
    await tester.pump();
    await tester.tap(find.byTooltip('Remix oluştur'));
    await tester.pump();
    expect(sent, isNull);

    await tester.tap(find.text('Kredi al'));
    expect(buyTapped, isTrue);
  });
}
