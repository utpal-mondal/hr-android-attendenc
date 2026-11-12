import 'package:office_management/core/common.dart';

IconData assetIcon(String type) => switch (type) {
      'Laptop' => Icons.laptop_mac,
      'Monitor' => Icons.desktop_windows_outlined,
      'Access Card' => Icons.badge_outlined,
      'Phone' => Icons.smartphone,
      _ => Icons.headset_mic_outlined,
    };

Color assetColor(String status) => switch (status) {
      'Assigned' => AppColors.info,
      'Available' => AppColors.success,
      _ => AppColors.warning,
    };

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'My Assets',
      subtitle: 'Company equipment assigned to you',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.assetsFor(app.me.id);
        if (list.isEmpty) return const EmptyState(title: 'No assets assigned', message: 'Equipment assigned to you will appear here.', icon: Icons.laptop_mac);
        return ResponsiveGrid(minTileWidth: 340, spacing: 12, children: [
          for (final a in list)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: AppColors.info.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                      child: Icon(assetIcon(a.type), color: AppColors.info),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(a.type, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      ]),
                    ),
                    StatusBadge(label: a.status, color: assetColor(a.status)),
                  ]),
                  const Divider(height: 24),
                  IconText(Icons.qr_code_2, 'Serial: ${a.serial}'),
                  const SizedBox(height: 4),
                  IconText(Icons.event_outlined, 'Assigned ${a.assignedOn == null ? '-' : Fmt.date(a.assignedOn!)}'),
                  const SizedBox(height: 10),
                  AppButton(label: 'Report an issue', icon: Icons.support_agent, type: AppButtonType.text, compact: true, onPressed: () => context.go('/employee/helpdesk')),
                ],
              ),
            ),
        ]);
      },
    );
  }
}
