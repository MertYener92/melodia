import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Profil ekranındaki "Şarkılarım" / "Videolarım" bölümleri: başlık, sağında
/// sayfa noktaları ve altında en fazla [rowsPerPage] satırlık sayfalar.
/// Daha fazla öğe varsa kullanıcı sağa kaydırarak sonraki sayfaya geçer;
/// bulunulan sayfanın noktası parlak ve geniş, diğerleri sönük görünür.
class PagedListSection extends StatefulWidget {
  const PagedListSection({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.rowsPerPage = 4,
    this.rowHeight = 68,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int rowsPerPage;
  final double rowHeight;

  @override
  State<PagedListSection> createState() => _PagedListSectionState();
}

class _PagedListSectionState extends State<PagedListSection> {
  final _controller = PageController();
  int _page = 0;

  int get _pageCount => (widget.itemCount / widget.rowsPerPage).ceil();

  @override
  void didUpdateWidget(covariant PagedListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Öğe silinip sayfa sayısı azaldıysa geçersiz sayfada kalma.
    if (_page >= _pageCount && _pageCount > 0) {
      _page = _pageCount - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) _controller.jumpToPage(_page);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rowsOnFirstPage = widget.itemCount.clamp(0, widget.rowsPerPage);
    final height =
        rowsOnFirstPage * widget.rowHeight + (rowsOnFirstPage - 1).clamp(0, 99);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_pageCount > 1) _PageDots(count: _pageCount, active: _page),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, page) {
              final start = page * widget.rowsPerPage;
              final end = (start + widget.rowsPerPage).clamp(
                0,
                widget.itemCount,
              );
              return Column(
                children: [
                  for (var i = start; i < end; i++) ...[
                    if (i > start)
                      const Divider(height: 1, color: AppColors.border),
                    SizedBox(
                      height: widget.rowHeight,
                      child: widget.itemBuilder(context, i),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(left: 5),
            width: i == active ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              gradient: i == active ? AppColors.primaryGradient : null,
              color: i == active ? null : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
