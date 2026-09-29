import 'dart:convert';
import '../domain/entities/subscription.dart';

/// Serializes subscriptions into shareable export formats.
class SubscriptionExporter {
  const SubscriptionExporter._();

  static String toJson(Iterable<Subscription> subs) {
    return const JsonEncoder.withIndent('  ').convert(subs.map((s) => s.toJson()).toList());
  }

  static String toCsv(Iterable<Subscription> subs) {
    String esc(String val) => val.replaceAll('"', '""');
    final buffer = StringBuffer();
    buffer.writeln('Name,Category,Billing Cycle,Price,Currency,Next Renewal,Status,Payment Method');
    for (final sub in subs) {
      final d = sub.nextBillingDate;
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        '"${esc(sub.name)}","${esc(sub.category.label)}","${esc(sub.billingCycle.label)}",${sub.price},"${esc(sub.currency)}","$dateStr","${esc(sub.status.label)}","${esc(sub.paymentMethod)}"',
      );
    }
    return buffer.toString();
  }
}
