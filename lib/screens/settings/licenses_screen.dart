import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../core/haptics/haptics.dart';

Future<Map<String, List<LicenseEntry>>>? _licensesByPackage;

/// [loadLicensesByPackage], read once per app run and shared by the list and detail pages.
/// About starts it shortly after it opens, so the list is usually ready before it's tapped.
Future<Map<String, List<LicenseEntry>>> licensesByPackage() => _licensesByPackage ??= loadLicensesByPackage();

/// Starts [licensesByPackage] once [context]'s page has finished sliding in.
void prefetchLicenses(BuildContext context) {
  if (_licensesByPackage != null) return;
  unawaited(_afterTransition(context).then((_) => licensesByPackage()));
}

/// Waits for [context]'s page to finish sliding in, so loading doesn't stutter the transition.
Future<void> _afterTransition(BuildContext context) {
  final animation = ModalRoute.of(context)?.animation;
  if (animation == null || animation.isCompleted) return Future.value();
  final done = Completer<void>();
  void listener(AnimationStatus status) {
    if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
      animation.removeStatusListener(listener);
      if (!done.isCompleted) done.complete();
    }
  }

  animation.addStatusListener(listener);
  return done.future;
}

/// Every licence registered with Flutter's [LicenseRegistry], grouped by package name.
Future<Map<String, List<LicenseEntry>>> loadLicensesByPackage() async {
  final byPackage = <String, List<LicenseEntry>>{};
  await for (final entry in LicenseRegistry.licenses) {
    for (final package in entry.packages) {
      (byPackage[package] ??= []).add(entry);
    }
  }
  final names = byPackage.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final n in names) n: byPackage[n]!};
}

/// Settings › About › Open source licences: a One UI list of packages.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  static Future<void> open(BuildContext context) {
    Haptics.tap();
    return context.push(AppRoutes.settingsLicenses);
  }

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  Future<Map<String, List<LicenseEntry>>>? _licenses;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _licenses ??= _afterTransition(context).then((_) => licensesByPackage());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<LicenseEntry>>>(
      future: _licenses,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return OneUISubpage(
          title: 'Open source licences',
          builder: (context) => [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                data == null
                    ? 'Loading…'
                    : 'One Spend is built with Flutter and ${data.length} open source packages. Thank you to their authors.',
                style: const TextStyle(fontSize: 14, height: 1.4, color: OneUITheme.textSecondary),
              ),
            ),
            if (data != null && data.isNotEmpty)
              OneUIGroupCard(
                margin: EdgeInsets.zero,
                items: [
                  for (final e in data.entries)
                    OneUIGroupItem(
                      title: e.key,
                      subtitle: '${e.value.length} licence${e.value.length == 1 ? '' : 's'}',
                      subtitleColor: OneUITheme.textSecondary,
                      onTap: () {
                        Haptics.tap();
                        context.push(AppRoutes.settingsLicenseDetail, extra: e.key);
                      },
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// The licence texts for one package.
class LicenseDetailScreen extends StatefulWidget {
  final String packageName;

  const LicenseDetailScreen({super.key, required this.packageName});

  @override
  State<LicenseDetailScreen> createState() => _LicenseDetailScreenState();
}

class _LicenseDetailScreenState extends State<LicenseDetailScreen> {
  /// Each licence's paragraphs, parsed once (parsing the text is the slow part).
  Future<List<List<LicenseParagraph>>>? _licenses;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _licenses ??= _afterTransition(context).then((_) => licensesByPackage()).then(
          (byPackage) => [for (final entry in byPackage[widget.packageName] ?? const <LicenseEntry>[]) entry.paragraphs.toList()],
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<LicenseParagraph>>>(
      future: _licenses,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <List<LicenseParagraph>>[];
        return OneUISubpage(
          title: widget.packageName,
          builder: (context) => [
            for (final (i, paragraphs) in entries.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final paragraph in paragraphs)
                      Padding(
                        padding: EdgeInsets.only(
                          left: paragraph.indent == LicenseParagraph.centeredIndent ? 0 : paragraph.indent * 12.0,
                          bottom: 10,
                        ),
                        child: Text(
                          paragraph.text,
                          textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                              ? TextAlign.center
                              : TextAlign.start,
                          style: const TextStyle(fontSize: 12.5, height: 1.45, color: OneUITheme.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
