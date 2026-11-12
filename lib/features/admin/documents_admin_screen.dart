import 'package:office_management/core/common.dart';
import 'package:office_management/features/documents/documents_screen.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  String _cat = 'All';
  String _query = '';

  void _upload(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    String category = 'HR Policy';
    bool picked = false;
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Upload document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setS(() => picked = !picked),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: picked ? AppColors.success : AppColors.border)),
                  child: Column(children: [
                    Icon(picked ? Icons.check_circle : Icons.cloud_upload_outlined, size: 34, color: picked ? AppColors.success : AppColors.teal),
                    const SizedBox(height: 8),
                    Text(picked ? 'document.pdf selected' : 'Tap to choose a file (demo)', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(label: 'Document title', controller: title, validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a title' : null),
              const SizedBox(height: 14),
              AppDropdown<String>(label: 'Category', items: const ['Employment', 'HR Policy', 'Company'], value: category, onChanged: (v) => setS(() => category = v ?? 'HR Policy')),
              const SizedBox(height: 20),
              AppButton(
                label: 'Upload',
                icon: Icons.upload_file_outlined,
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  if (!picked) {
                    showAppSnack(ctx, 'Please choose a file first.', error: true);
                    return;
                  }
                  app.addDocument(title.text.trim(), category);
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Document uploaded.');
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Documents',
      subtitle: 'Policies and company files',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Upload', icon: Icons.upload_file_outlined, compact: true, onPressed: () => _upload(context)),
        const SizedBox(width: 8),
      ],
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
              const AppCard(child: EmptyState(title: 'No documents', icon: Icons.folder_off_outlined))
            else
              ResponsiveGrid(minTileWidth: 440, spacing: 12, children: [
                for (final d in list)
                  DocumentCard(
                    document: d,
                    onView: () => showDocumentPreview(context, d),
                    onDelete: () async {
                      final ok = await showConfirmDialog(context, title: 'Delete document?', message: '"${d.title}" will be removed for all employees.', confirmLabel: 'Delete', destructive: true);
                      if (ok) {
                        app.deleteDocument(d);
                        if (context.mounted) showAppSnack(context, 'Document deleted.');
                      }
                    },
                  ),
              ]),
          ],
        );
      },
    );
  }
}
