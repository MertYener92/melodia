import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hızlı/Standart/Gelişmiş ekranlarında kullanılan ortak "hangi motor"
/// seçicisi. Üçünde de birebir aynı görünüm için buraya taşındı.
///
/// [value] 'suno' ya da 'lyria' olmalı (backend'in beklediği string
/// değerlerle birebir aynı — burada bir enum yerine bilinçli olarak
/// düz string kullanıldı, SunoApiService.generateAndWait'e doğrudan
/// aktarılabilsin diye).
class ProviderSelector extends StatelessWidget {
  const ProviderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _option(label: 'Suno', id: 'suno')),
          Expanded(child: _option(label: 'Lyria (Beta)', id: 'lyria')),
        ],
      ),
    );
  }

  Widget _option({required String label, required String id}) {
    final selected = value == id;
    return GestureDetector(
      onTap: () => onChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}