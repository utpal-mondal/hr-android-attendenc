import 'package:office_management/core/common.dart';

void showDocumentPreview(BuildContext context, DocumentItem d) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 8),
              Container(
                height: 280,
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 12, color: AppColors.border),
                    const SizedBox(height: 14),
                    for (var i = 0; i < 9; i++)
                      Padding(padding: const EdgeInsets.only(bottom: 9), child: Container(width: i % 4 == 3 ? 180 : double.infinity, height: 8, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('${d.extension} - ${d.size} - Updated ${Fmt.date(d.updated)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text('Preview placeholder - real document viewer comes with the API integration.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              AppButton(
                label: 'Download',
                icon: Icons.file_download_outlined,
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Downloading ${d.title} (demo)...');
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _query = '';
  String _cat = 'All';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Documents',
      subtitle: 'Policies, letters and company files',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final q = _query.toLowerCase();
        final list = app.documents.where((d) => (_cat == 'All' || d.category == _cat) && (q.isEmpty || d.title.toLowerCase().contains(q))).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(hint: 'Search documents', onChanged: (v) => setState(() => _query = v)),
            const Gap(12),
            AppFilterChips<String>(options: const ['All', 'Employment', 'HR Policy', 'Company'], selected: _cat, onSelected: (v) => setState(() => _cat = v)),
            const Gap(16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No documents', message: 'No files match your search.', icon: Icons.folder_off_outlined))
            else
              ResponsiveGrid(minTileWidth: 420, spacing: 12, children: [
                for (final d in list)
                  DocumentCard(
                    document: d,
                    onView: () => showDocumentPreview(context, d),
                    onDownload: () => showAppSnack(context, 'Downloading ${d.title} (demo)...'),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
