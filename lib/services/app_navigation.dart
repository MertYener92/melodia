import 'package:flutter/widgets.dart';

/// HomeShell'in sekme ve player gezinmesine, HomeShell'in ÜSTÜNE push edilen
/// ekranlardan (ör. üretim formları) erişim. Bu ekranlar HomeShell'in widget
/// ağacında olmadığı için callback'ler burada tutuluyor; HomeShell açılınca
/// bağlanır, kapanınca çözülür.
class AppNavigation {
  AppNavigation._();

  static const int libraryTab = 2;

  static void Function(int tab)? _goToTab;
  static VoidCallback? _openPlayer;

  static void attach({
    required void Function(int tab) goToTab,
    required VoidCallback openPlayer,
  }) {
    _goToTab = goToTab;
    _openPlayer = openPlayer;
  }

  static void detach() {
    _goToTab = null;
    _openPlayer = null;
  }

  /// Üstteki tüm sayfaları kapatıp Kütüphane sekmesine geçer -- orada alt
  /// sekmeler ve mini player görünür. HomeShell bağlı değilse false döner.
  static bool showLibrary(BuildContext context) {
    final goToTab = _goToTab;
    if (goToTab == null) return false;
    Navigator.of(context).popUntil((route) => route.isFirst);
    goToTab(libraryTab);
    return true;
  }

  static void openPlayer() => _openPlayer?.call();
}
