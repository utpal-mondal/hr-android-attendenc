import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/widgets.dart';
import '../models/enums.dart';
import 'nav_config.dart';

bool _matches(String location, String path) => location == path || location.startsWith('$path/');

/// Role-aware chrome: bottom bar (mobile), icon rail (tablet), sidebar (desktop).
class RoleShell extends StatelessWidget {
  const RoleShell({super.key, required this.role, required this.location, required this.child});
  final UserRole role;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = NavConfig.forRole(role);
    final width = Responsive.width(context);

    if (width < 600) {
      final primary = items.where((i) => i.primary).toList();
      final rest = items.where((i) => !i.primary).toList();
      var index = primary.indexWhere((i) => _matches(location, i.path));
      final hasMore = rest.isNotEmpty;
      if (index < 0) index = hasMore ? primary.length : 0;
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.teal.withValues(alpha:0.15),
          height: 66,
          selectedIndex: index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            if (i < primary.length) {
              context.go(primary[i].path);
            } else {
              _showMore(context, rest);
            }
          },
          destinations: [
            for (final i in primary) NavigationDestination(icon: Icon(i.icon), label: i.label),
            if (hasMore) const NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'More'),
          ],
        ),
      );
    }

    final expanded = width >= 1000;
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(role: role, items: items, location: location, expanded: expanded),
          Expanded(
            child: Column(
              children: [
                _TopBar(role: role),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMore(BuildContext context, List<NavItem> rest) {
    final router = GoRouter.of(context);
    showAppSheet<void>(
      context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: LayoutBuilder(builder: (context, c) {
                  final w = (c.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final i in rest)
                        SizedBox(
                          width: w,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(ctx);
                              router.go(i.path);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                              decoration: BoxDecoration(
                                color: _matches(location, i.path) ? AppColors.teal.withValues(alpha:0.10) : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(i.icon, color: AppColors.navy),
                                  const SizedBox(height: 6),
                                  Text(i.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: AppButton(
                label: 'Log out',
                icon: Icons.logout,
                type: AppButtonType.secondary,
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  performLogout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.role, required this.items, required this.location, required this.expanded});
  final UserRole role;
  final List<NavItem> items;
  final String location;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return Container(
      width: expanded ? 258 : 76,
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0, vertical: 20),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(child: Text('OfficeHub', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800))),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10),
                children: [for (final i in items) _tile(context, i)],
              ),
            ),
            const Divider(color: Color(0x22FFFFFF)),
            if (app.loaded)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 0, vertical: 12),
                child: Row(
                  mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    AvatarWidget(name: app.me.name, size: 36),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app.me.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                            Text(role.label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                        onPressed: () => performLogout(context),
                      ),
                    ],
                  ],
                ),
              ),
            if (!expanded)
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                onPressed: () => performLogout(context),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, NavItem i) {
    final selected = _matches(location, i.path);
    final tile = Material(
      color: selected ? Colors.white.withValues(alpha:0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(i.path),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 11),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(i.icon, size: 21, color: selected ? Colors.white : Colors.white60),
              if (expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(i.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: expanded ? tile : Tooltip(message: i.label, child: tile),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final showBell = role != UserRole.hr;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          StatusBadge(label: '${role.label} workspace', color: AppColors.teal, icon: Icons.verified_user_outlined),
          const Spacer(),
          if (showBell)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go('${role.basePath}/notifications'),
              icon: Badge(
                isLabelVisible: app.unreadCount > 0,
                label: Text('${app.unreadCount}'),
                child: const Icon(Icons.notifications_none),
              ),
            ),
          const SizedBox(width: 8),
          const AccountMenu(),
        ],
      ),
    );
  }
}
