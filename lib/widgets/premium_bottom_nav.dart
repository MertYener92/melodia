import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom navigation item'ının ikon ve etiket bilgisini taşıyan basit model.
class NavItemData {
  const NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Apple Music benzeri, seçili sekmeyi kayan bir pembe→mor gradient glow
/// ile gösteren premium alt navigasyon barı.
///
/// Aktif göstergenin (glow indicator) konumu item genişliklerine göre
/// [LayoutBuilder] ile dinamik hesaplanır; bu sayede hard-code pozisyon
/// kullanılmadan farklı ekran genişliklerinde (portrait/landscape, farklı
/// iPhone modelleri) doğru şekilde konumlanır.
///
/// Sekme değiştiğinde indicator, [AnimatedPositioned] sayesinde eski
/// konumdan yeni konuma fiziksel olarak kayarak geçer; art arda farklı
/// sekmelere basıldığında da mevcut anlık konumdan devam eder (teleport
/// etmez), çünkü implicit animasyonlar kesintiye uğradığında otomatik
/// olarak o anki değerden yeniden başlar.
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

  // ~250-400ms aralığında, premium/spring hissi veren süre ve easing.
  static const Duration _indicatorDuration = Duration(milliseconds: 320);
  static const Curve _indicatorCurve = Curves.easeOutBack;

  static const double _indicatorSize = 34;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          final indicatorLeft =
              itemWidth * currentIndex + (itemWidth - _indicatorSize) / 2;
          // İndikatör, ikonun tam dikey merkezine göre ortalanır
          // (öncelik: ikon ile mükemmel hizalanma).
          const indicatorTop = (_iconSize / 2) - (_indicatorSize / 2);

          return SizedBox(
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: _indicatorDuration,
                  curve: _indicatorCurve,
                  left: indicatorLeft,
                  top: indicatorTop,
                  child: const _GlowIndicator(size: _indicatorSize),
                ),
                Row(
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
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Aktif sekmenin arkasında beliren pembe→mor gradient, soft-glow daire.
class _GlowIndicator extends StatelessWidget {
  const _GlowIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.75,
          colors: [AppColors.pink, AppColors.purple],
        ),
        boxShadow: [
          // Sofistike, abartısız neon glow — simetrik (offset'siz) ki
          // daire her yöne eşit taşıp tam ortalı görünsün.
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.28),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
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

  static const Duration _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: _duration,
            curve: Curves.easeOutBack,
            scale: isSelected ? 1.0 : 0.92,
            child: AnimatedOpacity(
              duration: _duration,
              curve: Curves.easeOut,
              opacity: isSelected ? 1.0 : 0.5,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: _duration,
            curve: Curves.easeOut,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: AnimatedOpacity(
              duration: _duration,
              curve: Curves.easeOut,
              opacity: isSelected ? 1.0 : 0.55,
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}