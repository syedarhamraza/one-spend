/// Pure Dart Enums for Subscriptions (Zero Flutter framework dependencies)
library;

import 'custom_category.dart';

export 'custom_category.dart';

enum BillingCycle {
  weekly('Weekly', 52),
  monthly('Monthly', 12),
  quarterly('Quarterly', 4),
  yearly('Yearly', 1);

  final String label;
  final int occurrencesPerYear;
  const BillingCycle(this.label, this.occurrencesPerYear);

  static BillingCycle fromString(String? val) {
    return BillingCycle.values.firstWhere(
      (e) => e.name == val,
      orElse: () => BillingCycle.monthly,
    );
  }
}

/// A subscription's category: one of the 10 built-ins, or a user-made [CustomCategory].
///
/// Built-ins are `const` and custom categories are canonical instances (see [custom]), so
/// identity equality works and categories can be map keys and `const` map keys.
/// [name] is the stored id: the built-in name, or a custom category's `c_…` id.
class SubscriptionCategory {
  final String name;
  final String _label;
  final bool isCustom;

  const SubscriptionCategory._(this.name, this._label) : isCustom = false;
  SubscriptionCategory._custom(this.name)
      : _label = '',
        isCustom = true;

  static const entertainment = SubscriptionCategory._('entertainment', 'Entertainment');
  static const music = SubscriptionCategory._('music', 'Music & Audio');
  static const productivity = SubscriptionCategory._('productivity', 'Productivity & AI');
  static const cloud = SubscriptionCategory._('cloud', 'Cloud & Backup');
  static const gaming = SubscriptionCategory._('gaming', 'Gaming');
  static const design = SubscriptionCategory._('design', 'Design & Media');
  static const developer = SubscriptionCategory._('developer', 'Developer Tools');
  static const utilities = SubscriptionCategory._('utilities', 'Utilities');
  static const finance = SubscriptionCategory._('finance', 'Finance & Banking');
  static const health = SubscriptionCategory._('health', 'Health & Fitness');

  /// The built-in categories, in display order.
  static const values = [
    entertainment,
    music,
    productivity,
    cloud,
    gaming,
    design,
    developer,
    utilities,
    finance,
    health,
  ];

  static final Map<String, SubscriptionCategory> _customInstances = {};

  /// The canonical category for custom category [id].
  factory SubscriptionCategory.custom(String id) =>
      _customInstances.putIfAbsent(id, () => SubscriptionCategory._custom(id));

  /// Built-ins followed by the user's custom categories (pickers and filters).
  static List<SubscriptionCategory> get all => [
        ...values,
        for (final c in CustomCategoryRegistry.categories) SubscriptionCategory.custom(c.id),
      ];

  /// Display name. A custom category that no longer exists reads "Other".
  String get label => isCustom ? (CustomCategoryRegistry.byId(name)?.name ?? 'Other') : _label;

  /// The custom category's details, or null for a built-in (or a deleted custom one).
  CustomCategory? get custom => isCustom ? CustomCategoryRegistry.byId(name) : null;

  static SubscriptionCategory fromString(String? val) {
    if (val == null) return entertainment;
    for (final c in values) {
      if (c.name == val) return c;
    }
    if (CustomCategory.isCustomId(val)) return SubscriptionCategory.custom(val);
    return entertainment;
  }

  @override
  String toString() => 'SubscriptionCategory.$name';
}

enum SubscriptionStatus {
  active('Active', 0xFF00C05A),
  trial('Free Trial', 0xFF5390F5),
  dueSoon('Due Soon', 0xFFF07167),
  paused('Paused', 0xFF9E9EA4);

  final String label;
  final int colorValue;
  const SubscriptionStatus(this.label, this.colorValue);

  static SubscriptionStatus fromString(String? val) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

enum SubscriptionSortOption {
  renewalAsc('Next renewal (soonest)'),
  renewalDesc('Next renewal (latest)'),
  nameAsc('Name (A to Z)'),
  nameDesc('Name (Z to A)'),
  priceDesc('Price (High to low)'),
  priceAsc('Price (Low to high)');

  final String label;
  const SubscriptionSortOption(this.label);

  static SubscriptionSortOption fromString(String? val) {
    return SubscriptionSortOption.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionSortOption.renewalAsc,
    );
  }
}
