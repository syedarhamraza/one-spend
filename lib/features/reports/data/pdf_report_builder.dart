import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../currency/domain/money_format.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import 'report_data.dart';

/// Fonts for PDF reports. The PDF built-in fonts can't draw currency symbols,
/// so reports embed Noto Sans (see assets/fonts).
typedef ReportFonts = ({pw.Font regular, pw.Font bold});

/// Builds the PDF documents OneSpend shares: the full spending report and a
/// one-page sheet for a single subscription. Pure: data in, bytes out.
class PdfReportBuilder {
  const PdfReportBuilder._();

  static final _date = DateFormat('MMM d, y');
  static final _shortDate = DateFormat('MMM d');
  static final _month = DateFormat('MMM');

  static const _ink = PdfColor.fromInt(0xFF111114);
  static const _muted = PdfColor.fromInt(0xFF6B6B73);
  static const _faint = PdfColor.fromInt(0xFFB4B4BB);
  static const _tile = PdfColor.fromInt(0xFFF3F4F6);
  static const _rule = PdfColor.fromInt(0xFFE4E5E9);
  static const _blue = PdfColor.fromInt(0xFF0A6CFF);
  static const _blueSoft = PdfColor.fromInt(0xFFB9D3FF);
  static const _blueDark = PdfColor.fromInt(0xFF0750C2);

  /// Max pages for long payment histories (the pdf package defaults to 20).
  static const int _maxPages = 80;

  /// Currency symbols missing from Noto Sans, written as their codes instead.
  static String _pdfSafe(String text) => text.replaceAll('฿', 'THB ').replaceAll('৳', 'BDT ');

  static String _money(double amount, String code, {MoneyStyle style = MoneyStyle.exact}) =>
      _pdfSafe(formatMoney(amount, code, style: style));

  static pw.ThemeData _theme(ReportFonts fonts) => pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);

  // --- Spending report --------------------------------------------------------

  static Future<Uint8List> spendingReport(SpendingReportData d, ReportFonts fonts) {
    final doc = pw.Document(title: 'One Spend spending report', author: 'One Spend', creator: 'One Spend');
    final cur = d.currency;

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      theme: _theme(fonts),
      maxPages: _maxPages,
      footer: (context) => _footer(context, d.generatedAt),
      build: (context) => [
        _titleBand(
          'Spending report',
          [
            'Generated ${_date.format(d.generatedAt)}',
            'Amounts in $cur',
            if (d.categoryLabel != null) 'Category: ${d.categoryLabel}',
            if (d.selectionCount != null) '${d.selectionCount} selected subscription${d.selectionCount == 1 ? '' : 's'}',
          ].join('  ·  '),
        ),
        pw.SizedBox(height: 16),
        _tiles([
          ('Per month', _money(d.monthly, cur, style: MoneyStyle.summary)),
          ('Per year', _money(d.yearly, cur, style: MoneyStyle.summary)),
          ('Active', '${d.activeCount}'),
          if (d.monthlyBudget > 0)
            ('Of budget', '${(d.monthly / d.monthlyBudget * 100).round()}%')
          else
            ('Paused', '${d.pausedCount}'),
        ]),
        if (d.months.isNotEmpty) ...[
          _sectionTitle('Monthly spending', 'Past months use logged payments; lighter bars are forecast.'),
          _barChart(d.months, cur),
        ],
        if (d.categories.isNotEmpty) ...[
          _sectionTitle('By category', null),
          _categories(d.categories, cur),
        ],
        if (d.subscriptions.isNotEmpty) ...[
          _sectionTitle('Subscriptions', '${d.subscriptions.length} total, most expensive first'),
          _subscriptionTable(d),
        ],
        _sectionTitle('Upcoming renewals', 'Next ${SpendingReportData.upcomingDays} days'),
        if (d.upcoming.isEmpty)
          _empty('Nothing renews in the next ${SpendingReportData.upcomingDays} days.')
        else
          _chargeTable(d.upcoming, cur, total: d.upcoming.fold(0.0, (sum, c) => sum + c.amountInMain)),
        _sectionTitle('Payment history', 'Last ${SpendingReportData.historyMonths} months'),
        if (d.payments.isEmpty)
          _empty('No payments logged in this period.')
        else
          _chargeTable(d.payments, cur, total: d.paymentsTotal),
        pw.SizedBox(height: 14),
        pw.Text(
          'Monthly figures average each billing cycle (a \$120 yearly plan counts as \$10 a month). '
          'Other currencies are converted to $cur with your exchange rates.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    ));
    return doc.save();
  }

  // --- Single subscription ---------------------------------------------------

  static Future<Uint8List> subscriptionSheet(
    Subscription sub,
    ReportFonts fonts, {
    required String mainCurrency,
    required double Function(double amount, String code) toMain,
    String? paymentMethodName,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final doc = pw.Document(title: sub.name, author: 'One Spend', creator: 'One Spend');
    final lifetime = sub.paymentHistory.length * sub.price;
    final history = [...sub.paymentHistory]..sort((a, b) => b.compareTo(a));
    final rows = <(String, String)>[
      ('Price', '${_money(sub.price, sub.currency)} / ${sub.billingCycle.label.toLowerCase()}'),
      if (sub.currency != mainCurrency) ('In $mainCurrency', _money(toMain(sub.price, sub.currency), mainCurrency)),
      ('Per month', _money(toMain(sub.monthlyCost, sub.currency), mainCurrency)),
      ('Per year', _money(toMain(sub.yearlyCost, sub.currency), mainCurrency)),
      ('Next renewal', _date.format(sub.nextBillingDate)),
      ('Status', sub.status.label),
      ('Category', sub.category.label),
      if ((paymentMethodName ?? sub.paymentMethod).isNotEmpty) ('Payment method', paymentMethodName ?? sub.paymentMethod),
      ('Auto-renew', sub.autoRenew ? 'On' : 'Off'),
      if (sub.accountUrl.isNotEmpty) ('Website', sub.accountUrl),
      ('Lifetime spend', '${_money(lifetime, sub.currency)} (${sub.paymentHistory.length} payments)'),
    ];

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      theme: _theme(fonts),
      maxPages: _maxPages,
      footer: (context) => _footer(context, at),
      build: (context) => [
        _titleBand(_pdfSafe(sub.name), '${sub.category.label}  ·  Generated ${_date.format(at)}'),
        pw.SizedBox(height: 16),
        _tiles([
          ('Price', _money(sub.price, sub.currency)),
          ('Billing', sub.billingCycle.label),
          ('Next renewal', _shortDate.format(sub.nextBillingDate)),
        ]),
        _sectionTitle('Details', null),
        pw.Container(
          decoration: pw.BoxDecoration(color: _tile, borderRadius: pw.BorderRadius.circular(10)),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: pw.Column(
            children: [
              for (final (i, (label, value)) in rows.indexed)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 7),
                  decoration: i == rows.length - 1
                      ? null
                      : const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.6))),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(width: 130, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted))),
                      pw.Expanded(child: pw.Text(_pdfSafe(value), style: const pw.TextStyle(fontSize: 10.5, color: _ink))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (sub.notes.trim().isNotEmpty) ...[
          _sectionTitle('Notes', null),
          pw.Text(_pdfSafe(sub.notes.trim()), style: const pw.TextStyle(fontSize: 10.5, color: _ink, lineSpacing: 2)),
        ],
        _sectionTitle('Payment history', '${history.length} logged'),
        if (history.isEmpty)
          _empty('No payments logged yet.')
        else
          _chargeTable(
            [
              for (final d in history)
                (date: d, name: sub.name, amount: sub.price, currency: sub.currency, amountInMain: toMain(sub.price, sub.currency)),
            ],
            mainCurrency,
            total: history.length * toMain(sub.price, sub.currency),
            showName: false,
          ),
      ],
    ));
    return doc.save();
  }

  // --- Building blocks ---------------------------------------------------------

  static pw.Widget _titleBand(String title, String subtitle) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: pw.BoxDecoration(color: _blue, borderRadius: pw.BorderRadius.circular(14)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ONESPEND', style: pw.TextStyle(fontSize: 8.5, letterSpacing: 1.6, color: _blueSoft, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _tiles(List<(String, String)> tiles) {
    return pw.Row(
      children: [
        for (final (i, (label, value)) in tiles.indexed) ...[
          if (i > 0) pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: pw.BoxDecoration(color: _tile, borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
                  pw.SizedBox(height: 3),
                  pw.Text(value, maxLines: 1, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _ink)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, String? caption) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
          if (caption != null) ...[
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Text(caption, style: const pw.TextStyle(fontSize: 8.5, color: _muted))),
          ],
        ],
      ),
    );
  }

  static pw.Widget _empty(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: _tile, borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
      );

  /// Columns per month: past (blue), this month (dark blue), forecast (light blue).
  static pw.Widget _barChart(List<ReportMonth> months, String cur) {
    const chartHeight = 120.0;
    final peak = months.map((m) => m.amount).fold(0.0, math.max);
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: pw.BoxDecoration(color: _tile, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          for (final m in months)
            pw.Expanded(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    m.amount <= 0 ? '' : _money(m.amount, cur, style: MoneyStyle.summary),
                    maxLines: 1,
                    style: pw.TextStyle(fontSize: 6, color: m.isCurrent ? _ink : _muted),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 16,
                    height: peak <= 0 ? 1 : math.max(1, chartHeight * m.amount / peak),
                    decoration: pw.BoxDecoration(
                      color: m.isCurrent ? _blueDark : (m.isForecast ? _blueSoft : _blue),
                      borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _month.format(m.month),
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: m.isCurrent ? _ink : _muted,
                      fontWeight: m.isCurrent ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _categories(List<ReportCategory> categories, String cur) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: pw.BoxDecoration(color: _tile, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        children: [
          for (final c in categories)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(color: PdfColor.fromInt(c.colorValue), shape: pw.BoxShape.circle),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(width: 110, child: pw.Text(c.label, style: const pw.TextStyle(fontSize: 10, color: _ink))),
                  pw.Expanded(
                    child: pw.Stack(
                      children: [
                        pw.Container(height: 6, decoration: pw.BoxDecoration(color: _rule, borderRadius: pw.BorderRadius.circular(3))),
                        pw.LayoutBuilder(
                          builder: (context, constraints) => pw.Container(
                            width: math.max(2, (constraints?.maxWidth ?? 0) * c.share),
                            height: 6,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(c.colorValue),
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      '${_money(c.monthly, cur)}/mo',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink),
                    ),
                  ),
                  pw.SizedBox(
                    width: 34,
                    child: pw.Text(
                      '${(c.share * 100).round()}%',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _subscriptionTable(SpendingReportData d) {
    final cur = d.currency;
    return _table(
      headers: ['Subscription', 'Category', 'Billing', 'Price', 'Per month', 'Next renewal'],
      rightAligned: {3, 4},
      columnWidths: {0: 2.4, 1: 1.6, 2: 1.2, 3: 1.4, 4: 1.4, 5: 1.4},
      rows: [
        for (final s in d.subscriptions)
          [
            s.status == SubscriptionStatus.active ? s.name : '${s.name} (${s.status.label.toLowerCase()})',
            s.category.label,
            s.billingCycle.label,
            _money(s.price, s.currency),
            _money(d.toMain(s.monthlyCost, s.currency), cur),
            _date.format(s.nextBillingDate),
          ],
      ],
      mutedRows: {
        for (final (i, s) in d.subscriptions.indexed)
          if (s.status == SubscriptionStatus.paused) i,
      },
      footer: ['Total', '', '', '', _money(d.monthly, cur), ''],
    );
  }

  static pw.Widget _chargeTable(List<ReportCharge> charges, String cur, {required double total, bool showName = true}) {
    return _table(
      headers: [
        'Date',
        if (showName) 'Subscription',
        'Amount',
      ],
      rightAligned: {showName ? 2 : 1},
      columnWidths: showName ? {0: 1.4, 1: 3, 2: 1.6} : {0: 3, 1: 1.6},
      rows: [
        for (final c in charges)
          [
            _date.format(c.date),
            if (showName) c.name,
            c.currency == cur ? _money(c.amount, cur) : '${_money(c.amount, c.currency)}  (${_money(c.amountInMain, cur)})',
          ],
      ],
      footer: ['Total', if (showName) '${charges.length} charges', _money(total, cur)],
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, double> columnWidths,
    Set<int> rightAligned = const {},
    Set<int> mutedRows = const {},
    List<String>? footer,
  }) {
    pw.Widget cell(String text, int col, {bool header = false, bool bold = false, bool muted = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          _pdfSafe(text),
          textAlign: rightAligned.contains(col) ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: header ? 8 : 9,
            color: header ? _muted : (muted ? _faint : _ink),
            fontWeight: header || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.Table(
      columnWidths: {for (final e in columnWidths.entries) e.key: pw.FlexColumnWidth(e.value)},
      border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _rule, width: 0.6)),
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.8))),
          children: [for (final (i, h) in headers.indexed) cell(h.toUpperCase(), i, header: true)],
        ),
        for (final (r, row) in rows.indexed)
          pw.TableRow(children: [for (final (i, v) in row.indexed) cell(v, i, muted: mutedRows.contains(r))]),
        if (footer != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _ink, width: 0.8))),
            children: [for (final (i, v) in footer.indexed) cell(v, i, bold: true)],
          ),
      ],
    );
  }

  static pw.Widget _footer(pw.Context context, DateTime at) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        children: [
          pw.Text('One Spend  ·  ${_date.format(at)}', style: const pw.TextStyle(fontSize: 8, color: _faint)),
          pw.Spacer(),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _faint),
          ),
        ],
      ),
    );
  }
}
