import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ayarlar ve Hesap Bilgileri ekranlarının ORTAK yapı taşları: bölüm
/// başlığı + koyu yuvarlak kart + kart içindeki satırlar. İki ekran da
/// aynı görünümü paylaşsın diye buraya alındı (önceden settings_screen
/// içinde private'dı).

/// Kartın DIŞINDA, solda duran küçük bölüm başlığı.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Koyu, yuvarlak köşeli kart; satırlar arasına ikonun hizasından
/// başlayan ince ayırıcı çizgi koyar.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 0.6,
                indent: 54,
                color: AppColors.border,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Tek satır: solda ikon, ortada başlık.
///
/// [value] verilirse başlığın ALTINDA (salt okunur bilgi satırı), yoksa
/// satır tek satırlık bir menü öğesi gibi davranır. [onTap] varsa sağda
/// ">" oku çizilir; [trailing] bu oku ezer.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Kullanıcı ID gibi rastgele karakter dizileri için eşit genişlikli font.
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final Widget? end = trailing ??
        (onTap != null
            ? const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              )
            : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: hasValue ? 12 : 14,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: hasValue
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: hasValue ? 12 : 15,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: monospace ? 'monospace' : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (end != null) ...[const SizedBox(width: 8), end],
          ],
        ),
      ),
    );
  }
}
