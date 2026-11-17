import 'package:geolocator/geolocator.dart';
import 'package:office_management/core/common.dart';

const _radiusOptions = [50, 100, 200, 300, 500, 1000];

/// Fills [lat]/[lng] with the device's current GPS position (use while
/// standing in the office). Returns an error message, or null on success.
Future<String?> _fillCurrentLocation(TextEditingController lat, TextEditingController lng) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return 'Turn on location services first.';
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return 'Location permission is needed to read the office position.';
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
    lat.text = pos.latitude.toStringAsFixed(7);
    lng.text = pos.longitude.toStringAsFixed(7);
    return null;
  } catch (_) {
    return 'Could not read your location. Try again or type the coordinates.';
  }
}

String? _latValidator(String? v, TextEditingController other) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return other.text.trim().isEmpty ? null : 'Enter both latitude and longitude';
  final d = double.tryParse(t);
  return d == null || d < -90 || d > 90 ? 'Latitude must be between -90 and 90' : null;
}

String? _lngValidator(String? v, TextEditingController other) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return other.text.trim().isEmpty ? null : 'Enter both latitude and longitude';
  final d = double.tryParse(t);
  return d == null || d < -180 || d > 180 ? 'Longitude must be between -180 and 180' : null;
}

/// Latitude / longitude / radius inputs shared by the create and edit sheets.
class _LocationFields extends StatefulWidget {
  const _LocationFields({required this.lat, required this.lng, required this.radius, required this.onRadius});
  final TextEditingController lat;
  final TextEditingController lng;
  final int radius;
  final ValueChanged<int> onRadius;

  @override
  State<_LocationFields> createState() => _LocationFieldsState();
}

class _LocationFieldsState extends State<_LocationFields> {
  bool _locating = false;

  Future<void> _useCurrent() async {
    setState(() => _locating = true);
    final error = await _fillCurrentLocation(widget.lat, widget.lng);
    if (!mounted) return;
    setState(() => _locating = false);
    if (error != null) showAppSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Office location (check-in geofence)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Employees can only check in / out within the radius. Leave empty for no geofence.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: AppTextField(
            label: 'Latitude',
            controller: widget.lat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            validator: (v) => _latValidator(v, widget.lng),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            label: 'Longitude',
            controller: widget.lng,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            validator: (v) => _lngValidator(v, widget.lat),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      AppButton(
        label: 'Use my current location',
        icon: Icons.my_location,
        type: AppButtonType.secondary,
        loading: _locating,
        onPressed: _useCurrent,
      ),
      const SizedBox(height: 14),
      AppDropdown<int>(
        label: 'Allowed radius',
        items: _radiusOptions,
        itemLabel: (m) => '$m metres',
        value: widget.radius,
        onChanged: (v) => widget.onRadius(v ?? 100),
      ),
    ]);
  }
}

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  void _add(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final city = TextEditingController();
    final address = TextEditingController();
    final hours = TextEditingController(text: '09:30 AM - 06:30 PM');
    final lat = TextEditingController();
    final lng = TextEditingController();
    var radius = 100;
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('New branch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(label: 'Branch name', controller: name, validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a branch name' : null),
              const SizedBox(height: 14),
              AppTextField(label: 'City', controller: city, validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a city' : null),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Address',
                controller: address,
                maxLines: 2,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.length < 6) return 'Enter an address';
                  if (t.length > 255) return 'Address must be 255 characters or less';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(label: 'Working hours', controller: hours),
              const SizedBox(height: 20),
              _LocationFields(lat: lat, lng: lng, radius: radius, onRadius: (r) => setS(() => radius = r)),
              const SizedBox(height: 20),
              AppButton(
                label: 'Create branch',
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final la = double.tryParse(lat.text.trim());
                  final lo = double.tryParse(lng.text.trim());
                  app.addBranch(
                    name: name.text.trim(),
                    city: city.text.trim(),
                    address: address.text.trim(),
                    hours: hours.text.trim(),
                    latitude: la,
                    longitude: lo,
                    radiusMeters: la == null ? null : radius,
                  );
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Branch created.');
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _editLocation(BuildContext context, Branch b) {
    final formKey = GlobalKey<FormState>();
    final lat = TextEditingController(text: b.latitude?.toStringAsFixed(7) ?? '');
    final lng = TextEditingController(text: b.longitude?.toStringAsFixed(7) ?? '');
    var radius = _radiusOptions.contains(b.geofenceRadiusMeters) ? b.geofenceRadiusMeters! : 100;
    var busy = false;
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${b.name} location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _LocationFields(lat: lat, lng: lng, radius: radius, onRadius: (r) => setS(() => radius = r)),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save location',
                expand: true,
                loading: busy,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final la = double.tryParse(lat.text.trim());
                  final lo = double.tryParse(lng.text.trim());
                  setS(() => busy = true);
                  final ok = await app.setBranchLocation(b, latitude: la, longitude: lo, radiusMeters: la == null ? null : radius);
                  if (!ctx.mounted) return;
                  setS(() => busy = false);
                  if (!ok) return; // error already shown
                  Navigator.pop(ctx);
                  showAppSnack(context, la == null ? 'Geofence removed for ${b.name}.' : 'Location saved for ${b.name}.');
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
      title: 'Branches',
      subtitle: 'Office locations and working hours',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Add', icon: Icons.add, compact: true, onPressed: () => _add(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        return ResponsiveGrid(minTileWidth: 340, spacing: 14, children: [
          for (final b in app.branches)
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.navy.withValues(alpha:0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.apartment, color: AppColors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(b.city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ]),
                  ),
                  StatusBadge(label: '${app.employeeCountAt(b.name)} staff', color: AppColors.info),
                ]),
                const SizedBox(height: 12),
                IconText(Icons.location_on_outlined, b.address),
                const SizedBox(height: 6),
                IconText(Icons.schedule, b.workingHours),
                const SizedBox(height: 6),
                IconText(
                  b.hasGeofence ? Icons.radar : Icons.location_off_outlined,
                  b.hasGeofence
                      ? 'Geofence: ${b.geofenceRadiusMeters != null ? '${b.geofenceRadiusMeters} m' : 'default radius'}'
                      : 'No geofence - check-in allowed anywhere',
                  color: b.hasGeofence ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: b.hasGeofence ? 'Edit location' : 'Set location',
                  icon: Icons.edit_location_alt_outlined,
                  type: AppButtonType.secondary,
                  compact: true,
                  onPressed: () => _editLocation(context, b),
                ),
              ]),
            ),
        ]);
      },
    );
  }
}
