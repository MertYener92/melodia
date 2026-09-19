import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bildirimin anlamı -- ikon rozetinin rengini/ikonunu belirler.
enum NoticeType { success, info, warning, error, progress }

/// Uygulama genelinde TEK tip bildirim (toast). Mini player ile aynı görsel
/// dil: koyu, hafif bulanık yüzey, ince çerçeve, solda tipine göre ikon
/// rozeti, isteğe bağlı başlık + açıklama ve sağda hap şeklinde aksiyon.
///
/// Altta ScaffoldMessenger/SnackBar kullanır -- yani bildirimler sıraya
/// girer, alt navigasyonun üstünde durur ve aşağı kaydırılarak kapatılır.
class AppNotice {
  AppNotice._();

  static void show(
    BuildContext context,
    String message, {
    NoticeType type = NoticeType.info,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    showOn(
      ScaffoldMessenger.of(context),
      message,
      type: type,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Ekran kapanabilecek asenkron işlerde (ör. remix bitince) önceden
  /// alınmış [messenger] ile gösterir -- bildirim o an açık ekranda çıkar.
  static void showOn(
    ScaffoldMessengerState messenger,
    String message, {
    NoticeType type = NoticeType.info,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final hasAction = actionLabel != null && onAction != null;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          dismissDirection: DismissDirection.down,
          duration:
              duration ??
              (type == NoticeType.error || hasAction
                  ? const Duration(seconds: 5)
                  : const Duration(milliseconds: 3200)),
          content: _NoticeCard(
            type: type,
            title: title,
            message: message,
            actionLabel: hasAction ? actionLabel : null,
            onAction: hasAction
                ? () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  }
                : null,
          ),
        ),
      );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.type,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final NoticeType type;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.isNotEmpty;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1826).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  _NoticeBadge(type: type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTitle) ...[
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          message,
                          maxLines: hasTitle ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasTitle
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontSize: hasTitle ? 13 : 14,
                            fontWeight: hasTitle
                                ? FontWeight.w400
                                : FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(width: 10),
                    _NoticeAction(label: actionLabel!, onTap: onAction!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeBadge extends StatelessWidget {
  const _NoticeBadge({required this.type});

  final NoticeType type;

  static const _errorColor = Color(0xFFFF5C7A);
  static const _warningColor = Color(0xFFF4B740);

  @override
  Widget build(BuildContext context) {
    final (Gradient? gradient, Color? tint, Widget child) = switch (type) {
      NoticeType.success => (
        AppColors.playGradient,
        null,
        const Icon(Icons.check_rounded, color: Colors.white, size: 19),
      ),
      NoticeType.progress => (
        AppColors.playGradient,
        null,
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      ),
      NoticeType.info => (
        null,
        AppColors.purple,
        const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFFC4B5FD),
          size: 19,
        ),
      ),
      NoticeType.warning => (
        null,
        _warningColor,
        const Icon(Icons.schedule_rounded, color: _warningColor, size: 19),
      ),
      NoticeType.error => (
        null,
        _errorColor,
        const Icon(Icons.error_outline_rounded, color: _errorColor, size: 19),
      ),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: gradient,
        color: tint?.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: tint == null
            ? null
            : Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Center(child: child),
    );
  }
}

class _NoticeAction extends StatelessWidget {
  const _NoticeAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
