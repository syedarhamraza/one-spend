import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/services/insight_cards.dart';
import 'package:onespend/models/subscription.dart';

void main() {
  final now = DateTime(2026, 9, 24);

  Subscription sub(
    String id, {
    double price = 10,
    BillingCycle cycle = BillingCycle.monthly,
    SubscriptionStatus status = SubscriptionStatus.active,
    DateTime? next,
    List<DateTime> history = const [],
  }) =>
      Subscription(
        id: id,
        name: id,
        description: '',
        price: price,
        billingCycle: cycle,
        category: SubscriptionCategory.entertainment,
        status: status,
        nextBillingDate: next ?? DateTime(2026, 10, 5),
        paymentHistory: history,
      );

  List<InsightCardData> build(List<Subscription> subs, {double budget = 0, bool includeBudget = true, String? label}) =>
      InsightCards.build(
        subs,
        now: now,
        currency: '\$',
        monthlyBudget: budget,
        includeBudget: includeBudget,
        categoryLabel: label,
      );

  InsightCardData? byKey(List<InsightCardData> cards, String prefix) =>
      cards.where((c) => c.key.startsWith(prefix)).firstOrNull;

  test('over budget is a negative card keyed by month, skipped without includeBudget', () {
    final subs = [sub('a', price: 20), sub('b', price: 15)];
    final over = byKey(build(subs, budget: 30), 'all|over:')!;
    expect(over.key, 'all|over:2026-09');
    expect(over.tone, InsightTone.negative);
    expect(over.title, 'You\'re \$5 over budget');
    expect(over.action, InsightAction.showTopSubscriptions);

    expect(byKey(build(subs, budget: 30, includeBudget: false), 'all|over:'), isNull);
    expect(byKey(build(subs), 'all|over:'), isNull, reason: 'no budget set');
  });

  test('under budget is positive and acknowledges', () {
    final under = byKey(build([sub('a', price: 20), sub('b', price: 15)], budget: 100), 'all|under:')!;
    expect(under.tone, InsightTone.positive);
    expect(under.message, contains('35%'));
    expect(under.action, InsightAction.acknowledge);
  });

  test('spending up names the subscription that drove it', () {
    final cards = build([
      sub('steady', price: 20, next: DateTime(2026, 10, 10), history: [DateTime(2026, 8, 10), DateTime(2026, 9, 10)]),
      sub('annual', price: 99, cycle: BillingCycle.yearly, next: DateTime(2026, 9, 28)),
    ]);
    final up = byKey(cards, 'all|up:')!;
    expect(up.tone, InsightTone.negative);
    expect(up.message, contains('led by annual'));
    expect(up.action, InsightAction.showTrajectory);

    final yearly = byKey(cards, 'all|yearly:annual:2026-09-28')!;
    expect(yearly.tone, InsightTone.caution);
    expect(yearly.title, 'annual renews in 4 days');
    expect(yearly.subscription?.id, 'annual');
  });

  test('small changes are not notable', () {
    final cards = build([
      sub('a', price: 20, next: DateTime(2026, 10, 10), history: [DateTime(2026, 8, 10), DateTime(2026, 9, 10)]),
    ]);
    expect(byKey(cards, 'all|up:'), isNull);
    expect(byKey(cards, 'all|down:'), isNull);
  });

  test('spending down is positive', () {
    final down = byKey(
      build([sub('a', price: 20, next: DateTime(2026, 10, 10), history: [DateTime(2026, 8, 10), DateTime(2026, 8, 20)])]),
      'all|down:',
    )!;
    expect(down.tone, InsightTone.positive);
  });

  test('heavy month ahead and yearly heads-up window', () {
    final cards = build([
      sub('monthly', price: 10),
      sub('annual', price: 120, cycle: BillingCycle.yearly, next: DateTime(2026, 11, 2)),
    ]);
    final heavy = byKey(cards, 'all|heavy:')!;
    expect(heavy.key, 'all|heavy:2026-11');
    expect(heavy.title, 'November will be a heavy month');
    expect(heavy.message, contains('including annual \$120'));
    expect(byKey(cards, 'all|yearly:'), isNull, reason: '39 days away is outside the 30-day window');
  });

  test('paused savings and top expense', () {
    final cards = build([
      sub('big', price: 30),
      sub('small', price: 5),
      sub('held', price: 12, status: SubscriptionStatus.paused),
    ]);
    final paused = byKey(cards, 'all|paused:')!;
    expect(paused.title, 'Pausing saves \$12 a month');
    final top = byKey(cards, 'all|top:big')!;
    expect(top.tone, InsightTone.info);
    expect(top.title, 'big is 86% of your spending');
    expect(top.action, InsightAction.openSubscription);
  });

  test('cards are ordered negative, caution, positive, info', () {
    final cards = build(
      [
        sub('steady', price: 20, next: DateTime(2026, 10, 10), history: [DateTime(2026, 8, 10), DateTime(2026, 9, 10)]),
        sub('annual', price: 99, cycle: BillingCycle.yearly, next: DateTime(2026, 9, 28)),
        sub('held', price: 12, status: SubscriptionStatus.paused),
      ],
      budget: 10,
    );
    final tones = cards.map((c) => c.tone.index).toList();
    expect(tones, [...tones]..sort());
    expect(cards.first.tone, InsightTone.negative);
    expect(cards.last.tone, InsightTone.info);
  });

  test('a category filter scopes keys and wording', () {
    final cards = build([sub('a', price: 30), sub('b', price: 10)], label: 'Gaming');
    final top = byKey(cards, 'Gaming|top:a')!;
    expect(top.title, 'a is 75% of your Gaming spending');
  });
}
