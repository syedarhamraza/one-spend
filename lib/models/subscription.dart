import 'package:flutter/material.dart';

enum BillingCycle {
  weekly('Weekly', 52),
  monthly('Monthly', 12),
  quarterly('Quarterly', 4),
  yearly('Yearly', 1);

  final String label;
  final int occurrencesPerYear;
  const BillingCycle(this.label, this.occurrencesPerYear);
}

enum SubscriptionCategory {
  entertainment('Entertainment', Icons.movie_filter_rounded),
  music('Music & Audio', Icons.music_note_rounded),
  productivity('Productivity & AI', Icons.auto_awesome_rounded),
  cloud('Cloud & Backup', Icons.cloud_rounded),
  gaming('Gaming', Icons.sports_esports_rounded),
  design('Design & Media', Icons.palette_rounded),
  developer('Developer Tools', Icons.terminal_rounded),
  utilities('Utilities', Icons.build_rounded);

  final String label;
  final IconData icon;
  const SubscriptionCategory(this.label, this.icon);
}

enum SubscriptionStatus {
  active('Active', Color(0xFF00C05A)),
  trial('Free Trial', Color(0xFF5390F5)),
  dueSoon('Due in 3 days', Color(0xFFF07167)),
  paused('Paused', Color(0xFF9E9EA4));

  final String label;
  final Color color;
  const SubscriptionStatus(this.label, this.color);
}

class Subscription {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final SubscriptionCategory category;
  final Color brandColor;
  final IconData iconData;
  final DateTime nextBillingDate;
  final SubscriptionStatus status;
  final String paymentMethod;
  final int reminderDays;
  final bool isPopular;

  const Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = '\$',
    required this.billingCycle,
    required this.category,
    required this.brandColor,
    required this.iconData,
    required this.nextBillingDate,
    this.status = SubscriptionStatus.active,
    this.paymentMethod = 'Apple Pay •••• 4242',
    this.reminderDays = 2,
    this.isPopular = false,
  });

  Subscription copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    BillingCycle? billingCycle,
    SubscriptionCategory? category,
    Color? brandColor,
    IconData? iconData,
    DateTime? nextBillingDate,
    SubscriptionStatus? status,
    String? paymentMethod,
    int? reminderDays,
    bool? isPopular,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      brandColor: brandColor ?? this.brandColor,
      iconData: iconData ?? this.iconData,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reminderDays: reminderDays ?? this.reminderDays,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  double get monthlyCost {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return (price * 52) / 12;
      case BillingCycle.monthly:
        return price;
      case BillingCycle.quarterly:
        return (price * 4) / 12;
      case BillingCycle.yearly:
        return price / 12;
    }
  }
}

/// Catalog of Popular Subscriptions for quick 1-tap addition
final List<Subscription> popularCatalog = [
  Subscription(
    id: 'pop_netflix',
    name: 'Netflix',
    description: 'Premium Ultra HD 4K + HDR, 4 simultaneous screens',
    price: 22.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    brandColor: const Color(0xFFE50914),
    iconData: Icons.tv_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 4)),
    paymentMethod: 'Samsung Pay (Visa •••• 9124)',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_spotify',
    name: 'Spotify',
    description: 'Family Plan • 6 accounts, ad-free music & podcasts',
    price: 16.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.music,
    brandColor: const Color(0xFF1DB954),
    iconData: Icons.music_note_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 9)),
    paymentMethod: 'Mastercard •••• 4242',
    reminderDays: 3,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_chatgpt',
    name: 'ChatGPT Plus',
    description: 'Access to GPT-4o, DALL-E, advanced voice mode',
    price: 20.00,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.productivity,
    brandColor: const Color(0xFF10A37F),
    iconData: Icons.psychology_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 14)),
    paymentMethod: 'Apple Pay (Amex •••• 1004)',
    reminderDays: 1,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_youtube',
    name: 'YouTube Premium',
    description: 'Ad-free playback, background play, YouTube Music',
    price: 13.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    brandColor: const Color(0xFFFF0000),
    iconData: Icons.play_arrow_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 18)),
    paymentMethod: 'Google Pay •••• 7731',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_icloud',
    name: 'iCloud+',
    description: '2TB Cloud storage, Private Relay, Hide My Email',
    price: 9.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.cloud,
    brandColor: const Color(0xFF34AADC),
    iconData: Icons.cloud_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 22)),
    paymentMethod: 'Apple Account Balance',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_adobe',
    name: 'Adobe Creative Cloud',
    description: 'All Apps suite: Photoshop, Illustrator, Premiere Pro',
    price: 54.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.design,
    brandColor: const Color(0xFFFF4B4B),
    iconData: Icons.brush_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 27)),
    paymentMethod: 'Visa •••• 8812',
    reminderDays: 3,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_copilot',
    name: 'GitHub Copilot',
    description: 'Individual developer plan for AI code completions',
    price: 10.00,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.developer,
    brandColor: const Color(0xFF6E5494),
    iconData: Icons.terminal_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 11)),
    paymentMethod: 'PayPal • syed@onespend.app',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_disney',
    name: 'Disney+',
    description: 'Standard with Ads: Disney, Pixar, Marvel, Star Wars',
    price: 9.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    brandColor: const Color(0xFF113CCF),
    iconData: Icons.movie_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 16)),
    paymentMethod: 'Mastercard •••• 4242',
    reminderDays: 2,
    isPopular: true,
  ),
];

/// Reactive Global Store for Subscriptions
class SubscriptionStore extends ChangeNotifier {
  static final SubscriptionStore instance = SubscriptionStore._internal();
  factory SubscriptionStore() => instance;

  SubscriptionStore._internal() {
    // Initial dummy data pre-loaded
    _subscriptions.addAll([
      popularCatalog[0], // Netflix
      popularCatalog[1], // Spotify
      popularCatalog[2], // ChatGPT Plus
      popularCatalog[3], // YouTube Premium
      popularCatalog[4], // iCloud+
    ]);
  }

  final List<Subscription> _subscriptions = [];

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);

  double get totalMonthlySpend {
    return _subscriptions.fold(0.0, (acc, sub) => acc + sub.monthlyCost);
  }

  int get totalActiveCount {
    return _subscriptions.where((s) => s.status == SubscriptionStatus.active).length;
  }

  List<Subscription> get upcomingDue {
    final list = List<Subscription>.from(_subscriptions);
    list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return list;
  }

  void addSubscription(Subscription subscription) {
    _subscriptions.add(subscription);
    notifyListeners();
  }

  void removeSubscription(String id) {
    _subscriptions.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateSubscription(Subscription updated) {
    final index = _subscriptions.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _subscriptions[index] = updated;
      notifyListeners();
    }
  }
}
