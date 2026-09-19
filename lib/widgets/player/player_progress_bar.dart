import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// İnce, minimal ilerleme çubuğu + altında geçen süre / toplam süre.
///
/// Sürükleme sırasında çubuk oynatıcının canlı pozisyonunu DEĞİL,
/// kullanıcının parmağını takip eder; seek sadece bırakınca yapılır --
/// böylece sürüklerken thumb geri zıplamaz ve gereksiz seek isteği gitmez.
class PlayerProgressBar extends StatefulWidget {
  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
  double? _dragValue;

  static String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final hasDuration = totalMs > 0;
    final liveValue = hasDuration
        ? (widget.position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;
    final value = _dragValue ?? liveValue;
    final shownPosition = _dragValue != null
        ? Duration(milliseconds: (totalMs * _dragValue!).round())
        : widget.position;

    const timeStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              trackShape: const _GradientTrackShape(),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: _dragValue != null ? 7 : 5,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              overlayColor: Colors.white.withValues(alpha: 0.08),
            ),
            child: Slider(
              value: value,
              onChangeStart: hasDuration
                  ? (v) => setState(() => _dragValue = v)
                  : null,
              onChanged: hasDuration
                  ? (v) => setState(() => _dragValue = v)
                  : null,
              onChangeEnd: hasDuration
                  ? (v) {
                      setState(() => _dragValue = null);
                      widget.onSeek(
                        Duration(milliseconds: (totalMs * v).round()),
                      );
                    }
                  : null,
            ),
          ),
        ),
        Padding(
          // Slider'ın kendi yatay iç boşluğuyla (overlay yarıçapı) hizalı.
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(shownPosition), style: timeStyle),
              Text(
                hasDuration ? _format(widget.duration) : '--:--',
                style: timeStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aktif kısmı Melodia gradyanı (mor -> pembe), pasif kısmı soluk beyaz
/// olan yuvarlak uçlu ince track.
class _GradientTrackShape extends RoundedRectSliderTrackShape {
  const _GradientTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    final canvas = context.canvas;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.white24,
    );

    final activeRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      thumbCenter.dx,
      rect.bottom,
    );
    if (activeRect.width <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, radius),
      Paint()..shader = AppColors.primaryGradient.createShader(rect),
    );
  }
}
