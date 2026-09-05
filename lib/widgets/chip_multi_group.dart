import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// [ChipGroup]'un çoklu seçime izin veren versiyonu. Birden fazla pill
/// aynı anda seçili olabilir, wrap (satır sarma) layout kullanır — sihirbaz
/// sorularındaki "ne hissetsin?", "ses dünyası?" gibi çoklu seçimli
/// sorular için.
class ChipMultiGroup extends StatelessWidget {
  const ChipMultiGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.maxSelection,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Belirtilirse bu sayıya ulaşınca seçili olmayan pill'ler devre dışı
  /// görünür (opsiyonel, şu an sadece görsel ipucu amaçlı).
  final int? maxSelection;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        final atLimit = maxSelection != null &&
            !isSelected &&
            selected.length >= maxSelection!;

        return GestureDetector(
          onTap: atLimit ? null : () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : atLimit
                      ? AppColors.surfaceElevated.withValues(alpha: 0.5)
                      : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                ],
                Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : atLimit
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}