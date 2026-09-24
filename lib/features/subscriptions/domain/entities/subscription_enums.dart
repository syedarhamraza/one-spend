/// Pure Dart Enums for Subscriptions (Zero Flutter framework dependencies)
library;

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

enum SubscriptionCategory {
  entertainment('Entertainment'),
  music('Music & Audio'),
  productivity('Productivity & AI'),
  cloud('Cloud & Backup'),
  gaming('Gaming'),
  design('Design & Media'),
  developer('Developer Tools'),
  utilities('Utilities'),
  finance('Finance & Banking'),
  health('Health & Fitness');

  final String label;
  const SubscriptionCategory(this.label);

  static SubscriptionCategory fromString(String? val) {
    return SubscriptionCategory.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionCategory.entertainment,
    );
  }
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
