import 'package:flutter/material.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';

/// Presentation Layer UI Adapters for Subscriptions.
/// Decouples Flutter Material Widgets/Icons/Colors from Pure Dart Domain Entities.

const List<IconData> _supportedSubscriptionIcons = [
  Icons.movie_filter_rounded,
  Icons.movie_rounded,
  Icons.tv_rounded,
  Icons.play_arrow_rounded,
  Icons.music_note_rounded,
  Icons.album_rounded,
  Icons.headphones_rounded,
  Icons.auto_awesome_rounded,
  Icons.psychology_rounded,
  Icons.terminal_rounded,
  Icons.code_rounded,
  Icons.cloud_rounded,
  Icons.storage_rounded,
  Icons.sports_esports_rounded,
  Icons.videogame_asset_rounded,
  Icons.brush_rounded,
  Icons.palette_rounded,
  Icons.fitness_center_rounded,
  Icons.shopping_bag_rounded,
  Icons.shopping_cart_rounded,
  Icons.newspaper_rounded,
  Icons.school_rounded,
  Icons.wifi_rounded,
  Icons.shield_rounded,
  Icons.attach_money_rounded,
  Icons.subscriptions_rounded,
  Icons.star_rounded,
  Icons.build_rounded,
  Icons.account_balance_wallet_rounded,
  Icons.work_rounded,
  Icons.credit_card_rounded,
  Icons.payment_rounded,
  Icons.phone_android_rounded,
  Icons.laptop_rounded,
  Icons.book_rounded,
  Icons.pets_rounded,
  Icons.home_rounded,
  Icons.local_cafe_rounded,
  Icons.restaurant_rounded,
  Icons.directions_car_rounded,
  Icons.flight_rounded,
  Icons.lock_rounded,
  Icons.security_rounded,
  Icons.email_rounded,
  Icons.chat_rounded,
  Icons.web_rounded,
  Icons.apps_rounded,
];

final Map<int, IconData> _knownSubscriptionIcons = {
  for (final icon in _supportedSubscriptionIcons) icon.codePoint: icon,
};

IconData resolveSubscriptionIcon(int? codePoint, SubscriptionCategory category) {
  if (codePoint != null && _knownSubscriptionIcons.containsKey(codePoint)) {
    return _knownSubscriptionIcons[codePoint]!;
  }
  return category.icon;
}

extension SubscriptionUIAdapter on Subscription {
  Color get brandColor => Color(brandColorValue);
  IconData get iconData => resolveSubscriptionIcon(iconCodePoint, category);
}

extension SubscriptionCategoryUIAdapter on SubscriptionCategory {
  IconData get icon {
    switch (this) {
      case SubscriptionCategory.entertainment:
        return Icons.movie_filter_rounded;
      case SubscriptionCategory.music:
        return Icons.music_note_rounded;
      case SubscriptionCategory.productivity:
        return Icons.auto_awesome_rounded;
      case SubscriptionCategory.cloud:
        return Icons.cloud_rounded;
      case SubscriptionCategory.gaming:
        return Icons.sports_esports_rounded;
      case SubscriptionCategory.design:
        return Icons.palette_rounded;
      case SubscriptionCategory.developer:
        return Icons.terminal_rounded;
      case SubscriptionCategory.utilities:
        return Icons.build_rounded;
      case SubscriptionCategory.finance:
        return Icons.account_balance_wallet_rounded;
      case SubscriptionCategory.health:
        return Icons.fitness_center_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SubscriptionCategory.entertainment:
        return const Color(0xFFE50914);
      case SubscriptionCategory.music:
        return const Color(0xFF1DB954);
      case SubscriptionCategory.productivity:
        return const Color(0xFF5390F5);
      case SubscriptionCategory.cloud:
        return const Color(0xFF34AADC);
      case SubscriptionCategory.gaming:
        return const Color(0xFF7E57C2);
      case SubscriptionCategory.design:
        return const Color(0xFFFF4B4B);
      case SubscriptionCategory.developer:
        return const Color(0xFF6E5494);
      case SubscriptionCategory.utilities:
        return const Color(0xFF48B5A0);
      case SubscriptionCategory.finance:
        return const Color(0xFF00C05A);
      case SubscriptionCategory.health:
        return const Color(0xFFF4A261);
    }
  }
}

extension SubscriptionStatusUIAdapter on SubscriptionStatus {
  Color get color => Color(colorValue);
}
