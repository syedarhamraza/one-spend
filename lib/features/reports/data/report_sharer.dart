import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/di/injection.dart';
import '../../backup/data/backup_service.dart';
import '../../subscriptions/data/subscription_exporter.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import 'pdf_report_builder.dart';
import 'report_data.dart';
import 'text_report.dart';
import '../../../core/telemetry/events.dart';
import '../../../core/telemetry/telemetry.dart';

/// The formats the whole subscription list can be shared in.
enum ExportFormat { pdf, csv, text, backup }

/// Builds exports (PDF report, CSV, text, backup file) and hands them to the
/// system share sheet. Files go to the temporary directory with dated names.
class ReportSharer {
  const ReportSharer._();

  static ReportFonts? _fonts;

  /// Noto Sans from assets, loaded once.
  static Future<ReportFonts> loadFonts() async {
    final cached = _fonts;
    if (cached != null) return cached;
    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    return _fonts = (regular: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// A filesystem-safe version of [name] for file names.
  static String safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9 _.-]'), '').trim().replaceAll(RegExp(r'\s+'), '-');
    return cleaned.isEmpty ? 'subscription' : cleaned;
  }

  static Future<XFile> _file(String name, Uint8List bytes, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, mimeType: mimeType, name: name);
  }

  static Future<void> _shareFiles(List<XFile> files, String subject) async {
    await SharePlus.instance.share(ShareParams(files: files, subject: subject));
  }

  /// Shares the whole list (or one [category]) in [format].
  static Future<void> share(
    SubscriptionController store,
    ExportFormat format, {
    SubscriptionCategory? category,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    AppLog.event(TelemetryEvent.exportShared(format: format.name, scope: category == null ? 'all' : 'category'));
    final suffix = category == null ? '' : '-${safeFileName(category.label)}';
    final subs = [
      for (final s in store.subscriptions)
        if (category == null || s.category == category) s,
    ];
    switch (format) {
      case ExportFormat.pdf:
        final bytes = await PdfReportBuilder.spendingReport(
          SpendingReportData.fromStore(store, category: category, now: at),
          await loadFonts(),
        );
        await _shareFiles(
          [await _file('One-Spend-report$suffix-${_day(at)}.pdf', bytes, 'application/pdf')],
          'One Spend spending report',
        );
      case ExportFormat.csv:
        await _shareFiles(
          [
            await _file(
              'One-Spend-subscriptions$suffix-${_day(at)}.csv',
              Uint8List.fromList(utf8.encode(SubscriptionExporter.toCsv(subs))),
              'text/csv',
            ),
            await _file(
              'One-Spend-payments$suffix-${_day(at)}.csv',
              Uint8List.fromList(utf8.encode(SubscriptionExporter.paymentsCsv(subs))),
              'text/csv',
            ),
          ],
          'One Spend subscriptions',
        );
      case ExportFormat.text:
        await SharePlus.instance.share(
          ShareParams(text: TextReport.build(store, category: category, now: at), subject: 'One Spend spending report'),
        );
      case ExportFormat.backup:
        final contents = await sl<BackupService>().exportBackup(now: at);
        await _shareFiles(
          [await _file(BackupService.fileName(at), Uint8List.fromList(utf8.encode(contents)), 'application/json')],
          'One Spend backup',
        );
    }
  }

  /// Shares the subscriptions in [ids] (a selection) as a PDF report.
  static Future<void> shareSelectionPdf(SubscriptionController store, Set<String> ids, {DateTime? now}) async {
    AppLog.event(TelemetryEvent.exportShared(format: 'pdf', scope: 'selection'));
    final at = now ?? DateTime.now();
    final bytes = await PdfReportBuilder.spendingReport(
      SpendingReportData.fromStore(store, onlyIds: ids, now: at),
      await loadFonts(),
    );
    await _shareFiles(
      [await _file('One-Spend-${ids.length}-subscriptions-${_day(at)}.pdf', bytes, 'application/pdf')],
      'One Spend subscriptions (${ids.length})',
    );
  }

  /// Shares one subscription as a one-page PDF.
  static Future<void> shareSubscriptionPdf(SubscriptionController store, Subscription sub, {DateTime? now}) async {
    AppLog.event(TelemetryEvent.exportShared(format: 'pdf', scope: 'single'));
    final at = now ?? DateTime.now();
    final bytes = await PdfReportBuilder.subscriptionSheet(
      sub,
      await loadFonts(),
      mainCurrency: store.currency,
      toMain: store.toMain,
      paymentMethodName: store.getPaymentMethod(sub.paymentMethodId)?.displayName,
      now: at,
    );
    await _shareFiles(
      [await _file('${safeFileName(sub.name)}-${_day(at)}.pdf', bytes, 'application/pdf')],
      '${sub.name} subscription',
    );
  }
}
