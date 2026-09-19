import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../../services/song_library.dart';
import '../../theme/app_theme.dart';
import 'player_shared.dart';

/// Remix'in jeton maliyeti -- backend'deki creditPlans.js `remix` ile aynı
/// olmalı (backend istemcinin değerine güvenmiyor, bu sadece gösterim ve
/// ön kontrol için).
const int kRemixCreditCost = 10;

/// Bir tarz çipi: ekranda yerelleştirilmiş etiket, Suno'ya giden İngilizce
/// etiket (Suno İngilizce tarz tariflerinde en tutarlı sonucu veriyor).
class _StylePreset {
  const _StylePreset(this.sunoTag, this.label);

  final String sunoTag;
  final String Function(AppLocalizations) label;
}

final List<_StylePreset> _presets = [
  _StylePreset('acoustic', (l) => l.remixStyleAcoustic),
  _StylePreset('rock', (l) => l.remixStyleRock),
  _StylePreset('lo-fi', (l) => l.remixStyleLofi),
  _StylePreset('EDM', (l) => l.remixStyleEdm),
  _StylePreset('jazz', (l) => l.remixStyleJazz),
  _StylePreset('orchestral', (l) => l.remixStyleOrchestral),
  _StylePreset('R&B', (l) => l.remixStyleRnb),
  _StylePreset('trap', (l) => l.remixStyleTrap),
  _StylePreset('80s synthwave', (l) => l.remixStyle80s),
  _StylePreset('latin', (l) => l.remixStyleLatin),
];

/// Kullanıcının seçtiği remix ayarları.
class RemixRequest {
  const RemixRequest({
    required this.style,
    required this.styleLabel,
    required this.instrumental,
  });

  /// Suno'ya giden tarz tarifi (ör. "acoustic, lo-fi, yavaş tempo").
  final String style;

  /// Kütüphane kartında görünen kısa etiket (ör. "Akustik · Lo-fi").
  final String styleLabel;
  final bool instrumental;
}

/// Player'daki "Remix" butonunun açtığı kompakt panel: üstte şarkı, altında
/// yatay kayan tarz çipleri, en altta serbest tarif alanı + gönder butonu.
/// Klavye açıkken panel klavyenin hemen üstünde durur.
class RemixSheet extends StatefulWidget {
  const RemixSheet({
    super.key,
    required this.source,
    required this.availableCredits,
    required this.onSubmit,
    this.onBuyCredits,
  });

  final LibrarySong source;

  /// Kullanılabilir toplam jeton; bilinmiyorsa null (kontrolü backend yapar).
  final int? availableCredits;
  final ValueChanged<RemixRequest> onSubmit;
  final VoidCallback? onBuyCredits;

  @override
  State<RemixSheet> createState() => _RemixSheetState();
}

class _RemixSheetState extends State<RemixSheet> {
  static const int _maxPresets = 3;
  static const int _maxTextLength = 200;

  final _textController = TextEditingController();
  final Set<int> _selected = {};
  bool _instrumental = false;

  bool get _insufficient =>
      widget.availableCredits != null &&
      widget.availableCredits! < kRemixCreditCost;

  bool get _canSubmit =>
      !_insufficient &&
      (_selected.isNotEmpty ||
          _instrumental ||
          _textController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _togglePreset(int index) {
    setState(() {
      if (!_selected.remove(index) && _selected.length < _maxPresets) {
        _selected.add(index);
      }
    });
  }

  void _submit(AppLocalizations l10n) {
    if (!_canSubmit) return;
    final ordered = _selected.toList()..sort();
    final text = _textController.text.trim();
    final style = [
      for (final i in ordered) _presets[i].sunoTag,
      if (_instrumental) 'instrumental',
      if (text.isNotEmpty) text,
    ].join(', ');
    final chipLabel = [for (final i in ordered) _presets[i].label(l10n)]
        .join(' · ');
    final String styleLabel;
    if (chipLabel.isNotEmpty) {
      styleLabel = chipLabel;
    } else if (text.isNotEmpty) {
      styleLabel = text.length > 32 ? '${text.substring(0, 32)}…' : text;
    } else {
      styleLabel = l10n.remixInstrumental;
    }
    widget.onSubmit(
      RemixRequest(
        style: style,
        styleLabel: styleLabel,
        instrumental: _instrumental,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final song = widget.source.song;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    SongArtwork(imageUrl: song.imageUrl, size: 36, radius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            PlayerIcons.remix,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _CostPill(credits: kRemixCreditCost),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _StyleChip(
                      label: l10n.remixInstrumental,
                      icon: Icons.graphic_eq_rounded,
                      selected: _instrumental,
                      onTap: () =>
                          setState(() => _instrumental = !_instrumental),
                    ),
                    for (var i = 0; i < _presets.length; i++) ...[
                      const SizedBox(width: 8),
                      _StyleChip(
                        label: _presets[i].label(l10n),
                        selected: _selected.contains(i),
                        onTap: () => _togglePreset(i),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 3,
                          maxLength: _maxTextLength,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(l10n),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          cursorColor: AppColors.pink,
                          decoration: InputDecoration(
                            hintText: l10n.remixHint,
                            hintMaxLines: 1,
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _SendButton(
                          enabled: _canSubmit,
                          tooltip: l10n.remixCreate,
                          onTap: () => _submit(l10n),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_insufficient)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.remixCreditsNeeded,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (widget.onBuyCredits != null)
                        TextButton(
                          onPressed: widget.onBuyCredits,
                          child: Text(
                            l10n.remixBuyCredits,
                            style: const TextStyle(
                              color: AppColors.pink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  const _CostPill({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, color: Color(0xFFF4B740), size: 13),
          const SizedBox(width: 4),
          Text(
            '$credits',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textPrimary;
    return Material(
      color: selected
          ? AppColors.pink.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.07),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppColors.pink
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled ? AppColors.playGradient : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Icon(
              Icons.music_note_rounded,
              size: 20,
              color: enabled ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
