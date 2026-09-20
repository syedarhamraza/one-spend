import 'package:flutter/material.dart';
import '../models/subscription.dart';

class BrandPreset {
  final String id;
  final String name;
  final SubscriptionCategory category;
  final Color color;
  final Color textColor;
  final IconData icon;
  final String monogram;
  final String defaultUrl;
  final String? logoUrl;

  const BrandPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    this.textColor = Colors.white,
    required this.icon,
    required this.monogram,
    required this.defaultUrl,
    this.logoUrl,
  });
}

class OneUIBrandCatalog {
  static const List<BrandPreset> presets = [
    BrandPreset(
      id: 'netflix',
      name: 'Netflix',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFFE50914),
      icon: Icons.movie_filter_rounded,
      monogram: 'N',
      defaultUrl: 'https://www.netflix.com/youraccount',
      logoUrl: 'https://assets.nflxext.com/us/ffe/siteui/common/icons/nficon2016.png',
    ),
    BrandPreset(
      id: 'spotify',
      name: 'Spotify',
      category: SubscriptionCategory.music,
      color: Color(0xFF1DB954),
      icon: Icons.music_note_rounded,
      monogram: 'Sp',
      defaultUrl: 'https://www.spotify.com/account/overview',
    ),
    BrandPreset(
      id: 'apple_music',
      name: 'Apple Music',
      category: SubscriptionCategory.music,
      color: Color(0xFFFA243C),
      icon: Icons.album_rounded,
      monogram: '',
      defaultUrl: 'https://music.apple.com/account/settings',
    ),
    BrandPreset(
      id: 'apple_one',
      name: 'Apple One',
      category: SubscriptionCategory.utilities,
      color: Color(0xFF000000),
      icon: Icons.apple_rounded,
      monogram: '',
      defaultUrl: 'https://appleid.apple.com/account/manage',
    ),
    BrandPreset(
      id: 'apple_tv',
      name: 'Apple TV+',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFF1C1C1E),
      icon: Icons.tv_rounded,
      monogram: 'tv+',
      defaultUrl: 'https://tv.apple.com/settings',
    ),
    BrandPreset(
      id: 'youtube_premium',
      name: 'YouTube Premium',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFFFF0000),
      icon: Icons.smart_display_rounded,
      monogram: 'YT',
      defaultUrl: 'https://www.youtube.com/paid_memberships',
    ),
    BrandPreset(
      id: 'disney_plus',
      name: 'Disney+',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFF113CCF),
      icon: Icons.movie_creation_rounded,
      monogram: 'D+',
      defaultUrl: 'https://www.disneyplus.com/account',
    ),
    BrandPreset(
      id: 'amazon_prime',
      name: 'Amazon Prime',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFF00A8E1),
      icon: Icons.shopping_bag_rounded,
      monogram: 'PR',
      defaultUrl: 'https://www.amazon.com/mc/manageyourmembership',
    ),
    BrandPreset(
      id: 'hbo_max',
      name: 'Max / HBO',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFF002BE7),
      icon: Icons.theaters_rounded,
      monogram: 'MAX',
      defaultUrl: 'https://auth.max.com/account',
    ),
    BrandPreset(
      id: 'chatgpt',
      name: 'ChatGPT Plus',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF10A37F),
      icon: Icons.auto_awesome_rounded,
      monogram: 'GPT',
      defaultUrl: 'https://chatgpt.com/#settings/Subscription',
    ),
    BrandPreset(
      id: 'claude',
      name: 'Claude Pro',
      category: SubscriptionCategory.productivity,
      color: Color(0xFFD97757),
      icon: Icons.psychology_rounded,
      monogram: 'Cl',
      defaultUrl: 'https://claude.ai/settings/billing',
    ),
    BrandPreset(
      id: 'github_copilot',
      name: 'GitHub Copilot',
      category: SubscriptionCategory.developer,
      color: Color(0xFF24292F),
      icon: Icons.terminal_rounded,
      monogram: 'GH',
      defaultUrl: 'https://github.com/settings/billing',
    ),
    BrandPreset(
      id: 'notion',
      name: 'Notion',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF2F3437),
      icon: Icons.edit_note_rounded,
      monogram: 'N',
      defaultUrl: 'https://www.notion.so/settings',
    ),
    BrandPreset(
      id: 'figma',
      name: 'Figma',
      category: SubscriptionCategory.design,
      color: Color(0xFFF24E1E),
      icon: Icons.palette_rounded,
      monogram: 'Fg',
      defaultUrl: 'https://www.figma.com/settings',
    ),
    BrandPreset(
      id: 'slack',
      name: 'Slack',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF4A154B),
      icon: Icons.forum_rounded,
      monogram: 'Sl',
      defaultUrl: 'https://slack.com/admin/billing',
    ),
    BrandPreset(
      id: 'adobe_cc',
      name: 'Adobe Creative Cloud',
      category: SubscriptionCategory.design,
      color: Color(0xFFFF0000),
      icon: Icons.brush_rounded,
      monogram: 'Ai',
      defaultUrl: 'https://account.adobe.com/plans',
    ),
    BrandPreset(
      id: 'canva',
      name: 'Canva Pro',
      category: SubscriptionCategory.design,
      color: Color(0xFF00C4CC),
      icon: Icons.draw_rounded,
      monogram: 'Cv',
      defaultUrl: 'https://www.canva.com/settings/billing-and-plans',
    ),
    BrandPreset(
      id: 'dropbox',
      name: 'Dropbox',
      category: SubscriptionCategory.cloud,
      color: Color(0xFF0061FF),
      icon: Icons.folder_shared_rounded,
      monogram: 'DB',
      defaultUrl: 'https://www.dropbox.com/account/plan',
    ),
    BrandPreset(
      id: 'google_one',
      name: 'Google One',
      category: SubscriptionCategory.cloud,
      color: Color(0xFF4285F4),
      icon: Icons.cloud_rounded,
      monogram: 'G1',
      defaultUrl: 'https://one.google.com/settings',
    ),
    BrandPreset(
      id: 'google_workspace',
      name: 'Google Workspace',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF34A853),
      icon: Icons.business_center_rounded,
      monogram: 'GW',
      defaultUrl: 'https://admin.google.com/AdminHome',
    ),
    BrandPreset(
      id: 'microsoft_365',
      name: 'Microsoft 365',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF0078D4),
      icon: Icons.grid_view_rounded,
      monogram: 'M365',
      defaultUrl: 'https://account.microsoft.com/services',
    ),
    BrandPreset(
      id: 'xbox_game_pass',
      name: 'Xbox Game Pass',
      category: SubscriptionCategory.gaming,
      color: Color(0xFF107C10),
      icon: Icons.sports_esports_rounded,
      monogram: 'XB',
      defaultUrl: 'https://account.microsoft.com/services/xboxgamepass',
    ),
    BrandPreset(
      id: 'playstation_plus',
      name: 'PlayStation Plus',
      category: SubscriptionCategory.gaming,
      color: Color(0xFF003791),
      icon: Icons.gamepad_rounded,
      monogram: 'PS+',
      defaultUrl: 'https://store.playstation.com/subscriptions',
    ),
    BrandPreset(
      id: 'nintendo_switch_online',
      name: 'Nintendo Switch Online',
      category: SubscriptionCategory.gaming,
      color: Color(0xFFE60012),
      icon: Icons.videogame_asset_rounded,
      monogram: 'NSO',
      defaultUrl: 'https://ec.nintendo.com/my/membership',
    ),
    BrandPreset(
      id: 'discord_nitro',
      name: 'Discord Nitro',
      category: SubscriptionCategory.gaming,
      color: Color(0xFF5865F2),
      icon: Icons.chat_bubble_rounded,
      monogram: 'Ds',
      defaultUrl: 'https://discord.com/channels/@me',
    ),
    BrandPreset(
      id: 'twitch',
      name: 'Twitch Sub',
      category: SubscriptionCategory.entertainment,
      color: Color(0xFF9146FF),
      icon: Icons.live_tv_rounded,
      monogram: 'Tw',
      defaultUrl: 'https://www.twitch.tv/subscriptions',
    ),
    BrandPreset(
      id: 'medium',
      name: 'Medium',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF000000),
      icon: Icons.menu_book_rounded,
      monogram: 'M',
      defaultUrl: 'https://medium.com/me/settings/membership',
    ),
    BrandPreset(
      id: 'nytimes',
      name: 'The New York Times',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF121212),
      icon: Icons.newspaper_rounded,
      monogram: 'NYT',
      defaultUrl: 'https://www.nytimes.com/subscription',
    ),
    BrandPreset(
      id: 'audible',
      name: 'Audible',
      category: SubscriptionCategory.music,
      color: Color(0xFFF7991C),
      icon: Icons.headphones_rounded,
      monogram: 'Au',
      defaultUrl: 'https://www.audible.com/account/overview',
    ),
    BrandPreset(
      id: 'duolingo',
      name: 'Duolingo Super',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF58CC02),
      icon: Icons.school_rounded,
      monogram: 'Duo',
      defaultUrl: 'https://www.duolingo.com/settings/plus',
    ),
    BrandPreset(
      id: 'telegram_premium',
      name: 'Telegram Premium',
      category: SubscriptionCategory.utilities,
      color: Color(0xFF24A1DE),
      icon: Icons.send_rounded,
      monogram: 'TG',
      defaultUrl: 'https://telegram.org',
    ),
    BrandPreset(
      id: 'twitter_premium',
      name: 'X Premium',
      category: SubscriptionCategory.utilities,
      color: Color(0xFF000000),
      icon: Icons.close_rounded,
      monogram: '𝕏',
      defaultUrl: 'https://x.com/settings/manage_subscriptions',
    ),
    BrandPreset(
      id: 'linkedin_premium',
      name: 'LinkedIn Premium',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF0A66C2),
      icon: Icons.work_rounded,
      monogram: 'in',
      defaultUrl: 'https://www.linkedin.com/premium/manage',
    ),
    BrandPreset(
      id: 'strava',
      name: 'Strava Subscription',
      category: SubscriptionCategory.health,
      color: Color(0xFFFC4C02),
      icon: Icons.directions_run_rounded,
      monogram: 'St',
      defaultUrl: 'https://www.strava.com/settings',
    ),
    BrandPreset(
      id: 'uber_one',
      name: 'Uber One',
      category: SubscriptionCategory.utilities,
      color: Color(0xFF000000),
      icon: Icons.local_taxi_rounded,
      monogram: 'Ub',
      defaultUrl: 'https://m.uber.com/uber-one',
    ),
    BrandPreset(
      id: '1password',
      name: '1Password',
      category: SubscriptionCategory.utilities,
      color: Color(0xFF0A85EA),
      icon: Icons.password_rounded,
      monogram: '1P',
      defaultUrl: 'https://my.1password.com/profile',
    ),
    BrandPreset(
      id: 'nordvpn',
      name: 'NordVPN',
      category: SubscriptionCategory.utilities,
      color: Color(0xFF4687FF),
      icon: Icons.vpn_lock_rounded,
      monogram: 'NV',
      defaultUrl: 'https://my.nordaccount.com/dashboard/nordvpn',
    ),
    BrandPreset(
      id: 'coursera',
      name: 'Coursera Plus',
      category: SubscriptionCategory.productivity,
      color: Color(0xFF0056D2),
      icon: Icons.cast_for_education_rounded,
      monogram: 'Cs',
      defaultUrl: 'https://www.coursera.org/my-purchases',
    ),
  ];

  static BrandPreset? findPreset(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final normalized = name.trim().toLowerCase();
    for (final p in presets) {
      if (normalized == p.name.toLowerCase() ||
          normalized == p.id.toLowerCase() ||
          normalized.contains(p.name.toLowerCase()) ||
          p.name.toLowerCase().contains(normalized)) {
        return p;
      }
    }
    return null;
  }

  static BrandPreset? findById(String? id) {
    if (id == null) return null;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  static String getMonogram(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'S';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    }
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean.toUpperCase();
  }

  static Color getMonogramColor(String name) {
    final colors = [
      const Color(0xFF5390F5),
      const Color(0xFF00C05A),
      const Color(0xFF7E57C2),
      const Color(0xFFF4A261),
      const Color(0xFF48B5A0),
      const Color(0xFFE50914),
      const Color(0xFF10A37F),
      const Color(0xFF0078D4),
      const Color(0xFFD97757),
      const Color(0xFF0061FF),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }
}
