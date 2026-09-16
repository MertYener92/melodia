import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'gradient_border_painter.dart';

/// Bir öğenin (şarkı/video) hangi üretim modunda oluşturulduğunu temsil
/// eder. 'quick' = Hızlı, 'standard' = Standart, 'advanced' = Gelişmiş.
/// `null`, mod bilgisi taşımayan öğeler için (ör. henüz mod etiketi
/// eklenmemiş video klipleri ya da backend'den mod bilgisi olmadan
/// yüklenen eski şarkılar) -- bu öğeler SADECE "Tümü" seçiliyken
/// listede görünür.
class LibraryFilterMode {
  const LibraryFilterMode._(this.value, this.label);

  final String? value;
  final String label;

  static const all = LibraryFilterMode._(null, 'Tümü');
  static const quick = LibraryFilterMode._('quick', 'Hızlı');
  static const standard = LibraryFilterMode._('standard', 'Standart');
  static const advanced = LibraryFilterMode._('advanced', 'Gelişmiş');

  static const List<LibraryFilterMode> values = [all, quick, standard, advanced];

  bool matches(String? itemMode) => value == null || value == itemMode;
}

/// Kütüphane ekranlarındaki (Şarkılarım/Videolarım/Favorilerim) metin
/// tabanlı arama kutusunun YERİNİ ALAN, yatay kaydırılabilir filtre
/// çipleri satırı -- referans tasarımdaki (Tümü/Sihirbaz/Basit/Gelişmiş)
/// yapıyla aynı, ama programın kendi vurgu renkleriyle (purple/pink
/// gradyanı) ve üretim moduyla (Hızlı/Standart/Gelişmiş) eşleşen
/// etiketlerle.
class LibraryModeFilter extends StatelessWidget {
  const LibraryModeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final LibraryFilterMode selected;
  final ValueChanged<LibraryFilterMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: LibraryFilterMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = LibraryFilterMode.values[index];
          final isSelected = mode.value == selected.value;
          return _FilterChipPill(
            label: mode.label,
            isSelected: isSelected,
            onTap: () => onChanged(mode),
          );
        },
      ),
    );
  }
}

/// Seçili çipin çerçevesini çizen özel painter -- Flutter'ın standart
/// [Border]'ı tek düz renk destekler, gradyanlı (altınımsı, renk
/// geçişli) bir çerçeve için bu gerekiyor. İçi TAMAMEN şeffaf bırakılır
/// (fill yok, sadece stroke), böylece hangi ekranda kullanılırsa
/// kullanılsın (granit arka plan, düz koyu arka plan vb.) arkası olduğu
/// gibi görünür.
///
/// DEĞİŞTİ: Bu painter'ın kendisi artık widgets/gradient_border_painter.dart
/// dosyasında PAYLAŞILAN, public bir sınıf (GradientBorderPainter) --
/// premium geri butonu (premium_back_button.dart) da aynı painter'ı
/// kullanıyor, kod tekrarı önlenmiş oldu.

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _radius = 17;

  @override
  Widget build(BuildContext context) {
    // DEĞİŞTİ: Seçili çip -> tamamen şeffaf zemin + altınımsı, renk
    // geçişli (gradyanlı) çerçeve (bkz. _GradientBorderPainter). Seçili
    // OLMAYAN çipler -> hiçbir zemin/çerçeve yok, sadece metin -- önceki
    // "koyu dolgu + düz gri çerçeve" tasarımı tamamen kaldırıldı.
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: isSelected
            ? CustomPaint(
                painter: const GradientBorderPainter(
                  gradient: AppColors.goldGradient,
                  borderRadius: _radius,
                  strokeWidth: 1.4,
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}
