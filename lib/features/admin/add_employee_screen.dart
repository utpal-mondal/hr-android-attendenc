import 'package:office_management/core/common.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _designation = TextEditingController();
  String? _gender;
  String? _department;
  String? _branch;
  String? _shift;
  String? _managerId;
  String _type = 'Full-time';
  DateTime? _joinDate = dateOnly(DateTime.now());
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _designation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppController>();
    final email = _email.text.trim().toLowerCase();
    if (app.employees.any((e) => e.email.toLowerCase() == email)) {
      showAppSnack(context, 'An employee with this email already exists.', error: true);
      return;
    }
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final e = await app.addEmployee(
      name: _name.text.trim(),
      email: email,
      phone: _phone.text.trim(),
      gender: _gender!,
      department: _department!,
      designation: _designation.text.trim(),
      branch: _branch!,
      shift: _shift!,
      managerId: _managerId,
      joinDate: _joinDate!,
      employmentType: _type,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    await showSuccessDialog(context, title: 'Employee added', message: '${e.name} (${e.id}) has been added to ${e.department}.');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Add Employee',
      shimmer: ShimmerLayout.list,
      maxWidth: 860,
      builder: (context) {
        final app = context.watch<AppController>();
        final wide = Responsive.width(context) >= 700;
        Widget pair(Widget a, Widget b) => wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)])
            : Column(children: [a, const SizedBox(height: 14), b]);

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Personal details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Gap(16),
                  pair(
                    AppTextField(label: 'Full name', controller: _name, validator: (v) => (v == null || v.trim().length < 3) ? 'Enter the full name' : null),
                    AppTextField(
                      label: 'Work email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email' : null,
                    ),
                  ),
                  const Gap(14),
                  pair(
                    AppTextField(
                      label: 'Phone',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      hint: '+91 98XXXXXXXX',
                      validator: (v) => (v == null || v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) ? 'Enter a valid phone number' : null,
                    ),
                    AppDropdown<String>(label: 'Gender', items: const ['Female', 'Male', 'Other'], value: _gender, validator: (v) => v == null ? 'Select gender' : null, onChanged: (v) => setState(() => _gender = v)),
                  ),
                ]),
              ),
              const Gap(16),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Employment details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Gap(16),
                  pair(
                    AppDropdown<String>(label: 'Department', items: app.departments.map((d) => d.name).toList(), value: _department, validator: (v) => v == null ? 'Select department' : null, onChanged: (v) => setState(() => _department = v)),
                    AppTextField(label: 'Designation', controller: _designation, validator: (v) => (v == null || v.trim().length < 2) ? 'Enter designation' : null),
                  ),
                  const Gap(14),
                  pair(
                    AppDropdown<String>(label: 'Branch', items: app.branches.map((b) => b.name).toList(), value: _branch, validator: (v) => v == null ? 'Select branch' : null, onChanged: (v) => setState(() => _branch = v)),
                    AppDropdown<String>(label: 'Shift', items: app.shifts.map((s) => s.name).toList(), value: _shift, validator: (v) => v == null ? 'Select shift' : null, onChanged: (v) => setState(() => _shift = v)),
                  ),
                  const Gap(14),
                  pair(
                    AppDropdown<String>(
                      label: 'Reporting manager',
                      items: app.managers.map((m) => m.id).toList(),
                      itemLabel: (id) => '${app.nameOf(id)} (${app.employeeById(id)?.department ?? ''})',
                      value: _managerId,
                      hint: 'Select manager',
                      onChanged: (v) => setState(() => _managerId = v),
                    ),
                    AppDropdown<String>(label: 'Employment type', items: const ['Full-time', 'Part-time', 'Contract', 'Intern'], value: _type, onChanged: (v) => setState(() => _type = v ?? 'Full-time')),
                  ),
                  const Gap(14),
                  SizedBox(
                    width: wide ? 400 : double.infinity,
                    child: DateSelector(label: 'Joining date', value: _joinDate, firstDate: DateTime(2015), lastDate: DateTime(DateTime.now().year + 1, 12, 31), onChanged: (d) => setState(() => _joinDate = d)),
                  ),
                ]),
              ),
              const Gap(22),
              Row(children: [
                Expanded(child: AppButton(label: 'Cancel', type: AppButtonType.secondary, onPressed: () => context.pop())),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: AppButton(label: 'Create employee', icon: Icons.check, loading: _busy, onPressed: _submit)),
              ]),
            ],
          ),
        );
      },
    );
  }
}
