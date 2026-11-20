import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../repositories/app_repository.dart';
import '../widgets/widgets.dart';

/// File-name safe version of [name] (keeps letters, digits, dot, dash, underscore).
String safeFileName(String name) {
  final cleaned = name.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  return cleaned.isEmpty ? 'file' : cleaned;
}

/// Downloads with [download] into the app's documents folder, then opens the
/// file in the phone's default viewer. Shows progress and errors as snacks.
Future<void> downloadAndOpen(
  BuildContext context, {
  required String fileName,
  required Future<void> Function(String savePath) download,
}) async {
  showAppSnack(context, 'Downloading $fileName...');
  try {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}${Platform.pathSeparator}${safeFileName(fileName)}';
    await download(path);
    final result = await OpenFilex.open(path);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      showAppSnack(context, 'Saved $fileName, but no app on this phone can open it.', error: true);
    }
  } on RepoWriteException catch (e) {
    if (context.mounted) showAppSnack(context, e.message, error: true);
  } catch (_) {
    if (context.mounted) showAppSnack(context, 'Could not download $fileName. Please try again.', error: true);
  }
}

/// Saves [text] (e.g. a CSV export) to a file and opens it.
Future<void> saveTextAndOpen(BuildContext context, {required String fileName, required String text}) =>
    downloadAndOpen(context, fileName: fileName, download: (path) => File(path).writeAsString(text));

/// Opens a `mailto:`, `tel:` or web link; shows an error when nothing can handle it.
Future<void> openExternal(BuildContext context, Uri uri, {String? failMessage}) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) showAppSnack(context, failMessage ?? 'No app on this phone can open this.', error: true);
}
