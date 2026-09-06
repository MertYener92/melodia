import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom navigation item'ının ikon ve etiket bilgisini taşıyan basit model.
class NavItemData {
  const NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Sade, premium bir alt navigasyon barı: arka planda daire/glow YOK —
/// seçili sekmenin ikonu ve etiketi beyaza döner, diğerleri soluk kalır.
/// Sekmeler arası geçişte ikon/renk yumuşakça animasyonlanır, ayrıca
/// hafif bir "yukarı kalkma + zıplama" mikro-etkileşimi ile premium bir
/// his verir.
class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: SizedBox(
        height: 46,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: _NavItem(
                icon: item.icon,
                label: item.label,
                isSelected: index == currentIndex,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSlide(
        duration: _duration,
        curve: Curves.easeOutBack,
        offset: Offset(0, isSelected ? -0.08 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: _duration,
              curve: Curves.easeOutBack,
              scale: isSelected ? 1.08 : 1.0,
              child: TweenAnimationBuilder<Color?>(
                duration: _duration,
                curve: Curves.easeOut,
                tween: ColorTween(
                  end: isSelected ? Colors.white : AppColors.textMuted,
                ),
                builder: (context, color, _) {
                  return Icon(icon, color: color, size: 23);
                },
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: _duration,
              curve: Curves.easeOut,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}