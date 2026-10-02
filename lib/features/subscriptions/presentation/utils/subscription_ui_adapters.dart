import 'package:flutter/material.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';

/// Presentation Layer UI Adapters for Subscriptions.
/// Decouples Flutter Material Widgets/Icons/Colors from Pure Dart Domain Entities.

/// Every glyph a subscription or custom category can use. Icons are stored by code point and
/// resolved through this list, so release builds keep them when unused icons are tree-shaken.
const List<IconData> supportedSubscriptionIcons = [
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
  for (final icon in supportedSubscriptionIcons) icon.codePoint: icon,
};

/// The known glyph for [codePoint], or null if it isn't one of [supportedSubscriptionIcons].
IconData? resolveKnownIcon(int? codePoint) => codePoint == null ? null : _knownSubscriptionIcons[codePoint];

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

const Map<SubscriptionCategory, ({IconData icon, Color color})> _builtInCategoryStyle = {
  SubscriptionCategory.entertainment: (icon: Icons.movie_filter_rounded, color: Color(0xFFE50914)),
  SubscriptionCategory.music: (icon: Icons.music_note_rounded, color: Color(0xFF1DB954)),
  SubscriptionCategory.productivity: (icon: Icons.auto_awesome_rounded, color: Color(0xFF5390F5)),
  SubscriptionCategory.cloud: (icon: Icons.cloud_rounded, color: Color(0xFF34AADC)),
  SubscriptionCategory.gaming: (icon: Icons.sports_esports_rounded, color: Color(0xFF7E57C2)),
  SubscriptionCategory.design: (icon: Icons.palette_rounded, color: Color(0xFFEF6C9A)),
  SubscriptionCategory.developer: (icon: Icons.terminal_rounded, color: Color(0xFFFFD166)),
  SubscriptionCategory.utilities: (icon: Icons.build_rounded, color: Color(0xFF48B5A0)),
  SubscriptionCategory.finance: (icon: Icons.account_balance_wallet_rounded, color: Color(0xFF00C05A)),
  SubscriptionCategory.health: (icon: Icons.fitness_center_rounded, color: Color(0xFFF4A261)),
};

extension SubscriptionCategoryUIAdapter on SubscriptionCategory {
  /// A custom category's chosen glyph; a deleted one falls back to a neutral icon.
  IconData get icon =>
      _builtInCategoryStyle[this]?.icon ?? resolveKnownIcon(custom?.iconCodePoint) ?? Icons.label_rounded;

  Color get color {
    final builtIn = _builtInCategoryStyle[this];
    if (builtIn != null) return builtIn.color;
    final colorValue = custom?.colorValue;
    return colorValue == null ? const Color(0xFF9E9EA4) : Color(colorValue);
  }
}

extension SubscriptionStatusUIAdapter on SubscriptionStatus {
  Color get color => Color(colorValue);
}
