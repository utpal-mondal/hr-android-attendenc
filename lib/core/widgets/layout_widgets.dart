import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'account_menu.dart';
import 'feedback_widgets.dart';

/// Standard page wrapper: header (title, back arrow, actions), max-width body
/// and automatic shimmer / error gating while demo data loads.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.builder,
    this.subtitle,
    this.actions = const [],
    this.showAccount = false,
    this.maxWidth = 1180,
    this.shimmer = ShimmerLayout.dashboard,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showAccount;
  final double maxWidth;
  final ShimmerLayout shimmer;
  final WidgetBuilder builder;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final mobile = Responsive.isMobile(context);
    final canPop = Navigator.of(context).canPop();
    final pad = padding ?? EdgeInsets.fromLTRB(mobile ? 16 : 28, mobile ? 16 : 20, mobile ? 16 : 28, 32);

    Widget body;
    if (app.error != null) {
      body = ErrorState(message: app.error!, onRetry: app.load);
    } else if (!app.loaded) {
      body = SingleChildScrollView(
        padding: pad,
        physics: const NeverScrollableScrollPhysics(),
        child: _Bounded(maxWidth: maxWidth, child: LoadingShimmer(layout: shimmer)),
      );
    } else {
      body = SingleChildScrollView(
        padding: pad,
        child: _Bounded(maxWidth: maxWidth, child: Builder(builder: builder)),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(mobile ? 8 : 20, 10, mobile ? 8 : 20, 10),
            decoration: BoxDecoration(
              color: mobile ? Colors.white : Colors.transparent,
              border: mobile ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth + 24),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                      )
                    else
                      SizedBox(width: mobile ? 8 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: mobile ? 19 : 22, fontWeight: FontWeight.w700)),
                          if (subtitle != null)
                            Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ...actions,
                    if (showAccount && mobile) const AccountMenu(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Centers [child] and gives it a tight width of min(available, maxWidth).
class _Bounded extends StatelessWidget {
  const _Bounded({required this.maxWidth, required this.child});
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth < maxWidth ? c.maxWidth : maxWidth;
      return Center(child: SizedBox(width: w, child: child));
    });
  }
}

/// Wrap-based grid that adapts the column count to the available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minTileWidth = 260, this.spacing = 14});
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final int cols = ((w + spacing) / (minTileWidth + spacing)).floor().clamp(1, 6).toInt();
      final tile = (w - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final ch in children) SizedBox(width: tile, child: ch)],
      );
    });
  }
}

/// Two columns on wide screens, stacked on narrow ones.
class TwoColumn extends StatelessWidget {
  const TwoColumn({super.key, required this.left, required this.right, this.leftFlex = 3, this.rightFlex = 2, this.breakpoint = 900, this.gap = 20});
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= breakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, SizedBox(height: gap), right]);
    });
  }
}

/// Vertical spacing helper.
class Gap extends StatelessWidget {
  const Gap(this.h, {super.key});
  final double h;
  @override
  Widget build(BuildContext context) => SizedBox(height: h);
}

/// Table that scrolls horizontally on narrow screens.
class ScrollableTable extends StatelessWidget {
  const ScrollableTable({super.key, required this.columns, required this.rows, this.columnSpacing = 24});
  final List<String> columns;
  final List<List<Widget>> rows;
  final double columnSpacing;

  @override
  Widget build(BuildContext context) {
    return AppTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: (MediaQuery.sizeOf(context).width - 56).clamp(300.0, 1200.0).toDouble()),
          child: DataTable(
            columnSpacing: columnSpacing,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textSecondary),
            dividerThickness: 0.6,
            columns: [for (final c in columns) DataColumn(label: Text(c))],
            rows: [
              for (final r in rows) DataRow(cells: [for (final c in r) DataCell(c)]),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTableCard extends StatelessWidget {
  const AppTableCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
