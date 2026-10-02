import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../theme/one_ui_theme.dart';
import '../../../widgets/one_ui_group_card.dart';
import '../../../widgets/one_ui_subpage.dart';
import '../../../widgets/one_ui_toast.dart';
import '../../pro/presentation/pro_controller.dart';
import '../../pro/presentation/pro_gate.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../data/report_sharer.dart';

/// Export & share: pick a format for the whole list (or one category) and hand
/// it to the share sheet.
class ExportShareScreen extends StatefulWidget {
  /// Narrows the export to one category (e.g. from a filtered Analytics view).
  final SubscriptionCategory? category;

  const ExportShareScreen({super.key, this.category});

  static Future<void> open(BuildContext context, {SubscriptionCategory? category}) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.exportShare, extra: category);
  }

  @override
  State<ExportShareScreen> createState() => _ExportShareScreenState();
}

class _ExportShareScreenState extends State<ExportShareScreen> {
  /// The export being prepared, shown with a spinner on its row.
  ExportFormat? _busy;

  Future<void> _share(ExportFormat format) async {
    if (_busy != null) return;
    final store = SubscriptionController.instance;
    if (format != ExportFormat.backup && store.subscriptions.isEmpty) {
      OneUIToast.show(context, 'Add a subscription first');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _busy = format);
    try {
      await ReportSharer.share(store, format, category: widget.category);
    } catch (_) {
      if (mounted) OneUIToast.show(context, 'Couldn\'t prepare the export');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _trailing(ExportFormat format) {
    if (_busy == format) {
      return const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: OneUITheme.accentBlue),
      );
    }
    const share = Icon(Icons.ios_share_rounded, size: 20, color: OneUITheme.textSecondary);
    return format == ExportFormat.pdf ? ProGate.chip(unlocked: share) : share;
  }

  OneUIGroupItem _item(ExportFormat format, IconData icon, Color color, String title, String subtitle) {
    return OneUIGroupItem(
      leading: OneUIIconBadge(icon, color),
      title: title,
      subtitle: subtitle,
      subtitleColor: OneUITheme.textSecondary,
      trailing: _trailing(format),
      onTap: format == ExportFormat.pdf ? () => ProGate.run(context, () => _share(format)) : () => _share(format),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return OneUISubpage(
      title: 'Export & share',
      listenable: ProController.instance,
      builder: (context) => [
        if (category != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Only ${category.label} subscriptions are included.',
              style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
            ),
          ),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            _item(ExportFormat.pdf, Icons.picture_as_pdf_rounded, OneUITheme.accentRed, 'PDF report',
                'Totals, monthly chart, categories, renewals and payment history'),
            _item(ExportFormat.csv, Icons.table_chart_rounded, OneUITheme.accentGreen, 'Spreadsheet (CSV)',
                'Subscriptions and payments, for Excel or Google Sheets'),
            _item(ExportFormat.text, Icons.notes_rounded, OneUITheme.accentBlue, 'Text summary',
                'A short summary to paste into a message'),
          ],
        ),
        if (category == null) ...[
          const SizedBox(height: 14),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              _item(ExportFormat.backup, Icons.backup_rounded, OneUITheme.accentAmber, 'Backup file',
                  'Everything, to restore on another phone'),
            ],
          ),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Exports are created on this phone and only leave it through the app you share them with.',
            style: TextStyle(fontSize: 12.5, height: 1.35, color: OneUITheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
