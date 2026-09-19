import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import 'package:melodia/models/song.dart';
import 'package:melodia/services/song_library.dart';
import 'package:melodia/widgets/player/player_progress_bar.dart';
import 'package:melodia/widgets/player/player_shared.dart';

LibrarySong _song({String genre = '', String mood = ''}) => LibrarySong(
  song: Song(
    id: 'id-1',
    title: 'Çok uzun bir şarkı başlığı ki kesinlikle tek satıra sığmamalı',
    prompt: '',
    audioUrl: '',
    streamAudioUrl: '',
    imageUrl: '',
  ),
  genre: genre,
  mood: mood,
  createdAt: DateTime(2026),
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('tr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('playerSubtitle', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));

    test('tür ve ruh hali varsa ikisini birleştirir', () {
      expect(
        playerSubtitle(_song(genre: 'Pop', mood: 'Enerjik'), l10n),
        'Pop · Enerjik',
      );
    });

    test('metadata yoksa "AI ile üretildi" gösterir', () {
      expect(playerSubtitle(_song(), l10n), l10n.playerAiGenerated);
    });
  });

  testWidgets('PlayerProgressBar süreleri mm:ss formatında gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 360,
          child: PlayerProgressBar(
            position: const Duration(seconds: 8),
            duration: const Duration(minutes: 3, seconds: 38),
            onSeek: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('00:08'), findsOneWidget);
    expect(find.text('03:38'), findsOneWidget);
  });

  testWidgets('PlayerProgressBar bırakınca seek eder', (tester) async {
    Duration? seeked;
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 360,
          child: PlayerProgressBar(
            position: Duration.zero,
            duration: const Duration(seconds: 100),
            onSeek: (d) => seeked = d,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    expect(seeked, isNotNull);
    expect(seeked!.inSeconds, inInclusiveRange(40, 60));
  });

  testWidgets('PlayerProgressBar süre bilinmiyorsa --:-- gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 360,
          child: PlayerProgressBar(
            position: Duration.zero,
            duration: Duration.zero,
            onSeek: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('--:--'), findsOneWidget);
  });

  testWidgets('SongArtwork görsel yoksa yer tutucu gösterir ve kare kalır', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const SongArtwork(imageUrl: '', size: 120, radius: 12)),
    );
    expect(find.byIcon(PlayerIcons.placeholder), findsOneWidget);
    expect(tester.getSize(find.byType(SongArtwork)), const Size(120, 120));
  });
}
