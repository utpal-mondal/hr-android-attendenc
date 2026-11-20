import 'package:geocoding/geocoding.dart' as geo;
import 'package:office_management/core/common.dart';
import 'package:url_launcher/url_launcher.dart';

/// Within this distance of the branch a punch reads as "At office".
const _atOfficeMeters = 150;

String _distance(int m) => m < 1000 ? '$m m' : '${(m / 1000).toStringAsFixed(m < 10000 ? 1 : 0)} km';

/// One-line summary of where a punch happened. WFH punches have no distance
/// limit, so they only say a location was recorded (never "km from office").
String punchPlaceLabel(PunchLocation? l, {bool wfh = false}) {
  if (l == null || !l.isReal) return 'No location';
  if (wfh) return 'Location recorded';
  final d = l.distanceFromOfficeMeters;
  if (d == null) return 'Location recorded';
  if (d <= _atOfficeMeters) return 'At office';
  return '${_distance(d)} from office';
}

/// Summary of a day's check-in and check-out places, e.g.
/// "WFH · 4.2 km from office" or "In: At office · Out: 1.1 km from office".
String attendancePlaceSummary(Attendance a) {
  final inL = punchPlaceLabel(a.checkInLocation, wfh: a.isWfh);
  final hasOut = a.checkOut != null;
  final outL = punchPlaceLabel(a.checkOutLocation, wfh: a.isWfh);
  final body = !hasOut || outL == inL ? inL : 'In: $inL · Out: $outL';
  return a.isWfh ? 'WFH · $body' : body;
}

/// Reverse-geocoded street address, cached per coordinate (uses the phone's
/// built-in geocoder, so no API key is needed). Null when unavailable.
final _addressCache = <String, Future<String?>>{};

Future<String?> addressFor(PunchLocation l) {
  final key = '${l.latitude.toStringAsFixed(5)},${l.longitude.toStringAsFixed(5)}';
  return _addressCache.putIfAbsent(key, () async {
    try {
      final marks = await geo.Geocoding().placemarkFromCoordinates(l.latitude, l.longitude);
      if (marks.isEmpty) return null;
      final p = marks.first;
      final parts = <String>[];
      for (final s in [p.name, p.street, p.subLocality, p.locality, p.administrativeArea, p.postalCode]) {
        final v = s?.trim() ?? '';
        if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
      }
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  });
}

Future<void> openInMaps(BuildContext context, PunchLocation l) async {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${l.latitude},${l.longitude}');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) showAppSnack(context, 'Could not open Maps.', error: true);
}

/// Tappable "where" cell for attendance lists: icon + summary, opens the
/// full check-in / check-out location sheet.
class AttendancePlaceLink extends StatelessWidget {
  const AttendancePlaceLink({super.key, required this.record, required this.employeeName});
  final Attendance? record;
  final String employeeName;

  @override
  Widget build(BuildContext context) {
    final a = record;
    if (a == null || a.checkIn == null) return const Text('--');
    final anyLocation = (a.checkInLocation?.isReal ?? false) || (a.checkOutLocation?.isReal ?? false);
    if (!anyLocation) {
      // Nothing to show on a map, so no link (e.g. punches before GPS capture).
      return const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_off_outlined, size: 15, color: AppColors.textSecondary),
        SizedBox(width: 5),
        Text('Not recorded', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]);
    }
    final color = a.isWfh ? AppColors.info : AppColors.teal;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => showPunchLocationsSheet(context, a, employeeName: employeeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(a.isWfh ? Icons.home_work_outlined : Icons.location_on_outlined, size: 16, color: color),
          const SizedBox(width: 5),
          Flexible(child: _summaryText(a, color)),
        ]),
      ),
    );
  }
}

/// For WFH, shows the check-in address ("WFH · Salt Lake, Kolkata") once it
/// resolves; office days show the distance summary.
Widget _summaryText(Attendance a, Color color) {
  final style = TextStyle(color: color, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: color.withValues(alpha: 0.4));
  Widget text(String s) => Text(s, overflow: TextOverflow.ellipsis, style: style);
  final l = a.checkInLocation;
  if (!a.isWfh || l == null || !l.isReal) return text(attendancePlaceSummary(a));
  return FutureBuilder<String?>(
    future: addressFor(l),
    builder: (context, snap) => text(snap.data == null ? attendancePlaceSummary(a) : 'WFH · ${snap.data}'),
  );
}

Future<void> showPunchLocationsSheet(BuildContext context, Attendance a, {required String employeeName}) {
  return showAppSheet<void>(
    context,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(employeeName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Row(children: [
          Expanded(child: Text(Fmt.fullDate(a.date), style: const TextStyle(color: AppColors.textSecondary))),
          attendanceBadge(a.status),
        ]),
        const SizedBox(height: 16),
        PunchLocationTile(title: 'Check-in', time: a.checkIn, location: a.checkInLocation, showDistance: !a.isWfh),
        const SizedBox(height: 12),
        if (a.checkOut != null)
          PunchLocationTile(title: 'Check-out', time: a.checkOut, location: a.checkOutLocation, showDistance: !a.isWfh)
        else
          const Text('Not checked out yet.', style: TextStyle(color: AppColors.textSecondary)),
      ]),
    ),
  );
}

/// Full details of one punch: address, coordinates, accuracy, distance from
/// the office and a link to the map.
class PunchLocationTile extends StatelessWidget {
  const PunchLocationTile({super.key, required this.title, required this.time, required this.location, this.showDistance = true});
  final String title;
  final DateTime? time;
  final PunchLocation? location;

  /// False for WFH punches: there is no distance limit, only the place.
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    final l = location;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(Fmt.time(time), style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        if (l == null || !l.isReal)
          const Text('No location was recorded for this punch.', style: TextStyle(color: AppColors.textSecondary))
        else ...[
          FutureBuilder<String?>(
            future: addressFor(l),
            builder: (context, snap) => IconText(
              Icons.place_outlined,
              snap.connectionState != ConnectionState.done
                  ? 'Looking up address...'
                  : (snap.data ?? 'Address unavailable'),
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          IconText(Icons.my_location, '${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}'
              '${l.accuracyMeters > 0 ? '  (±${l.accuracyMeters} m)' : ''}'),
          if (showDistance && l.distanceFromOfficeMeters != null) ...[
            const SizedBox(height: 6),
            IconText(
              Icons.apartment_outlined,
              l.distanceFromOfficeMeters! <= _atOfficeMeters
                  ? 'At ${l.officeName ?? 'the office'} (${_distance(l.distanceFromOfficeMeters!)})'
                  : '${_distance(l.distanceFromOfficeMeters!)} from ${l.officeName ?? 'the office'}',
              color: l.distanceFromOfficeMeters! <= _atOfficeMeters ? AppColors.success : AppColors.warning,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            AppButton(label: 'Open in Maps', icon: Icons.map_outlined, compact: true, type: AppButtonType.secondary, onPressed: () => openInMaps(context, l)),
            AppButton(
              label: 'Copy',
              icon: Icons.copy,
              compact: true,
              type: AppButtonType.secondary,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${l.latitude},${l.longitude}'));
                showAppSnack(context, 'Coordinates copied.');
              },
            ),
          ]),
        ],
      ]),
    );
  }
}
