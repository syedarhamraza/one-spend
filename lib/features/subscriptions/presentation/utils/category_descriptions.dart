import '../../domain/entities/subscription_enums.dart';

/// What each built-in category covers: a short line for lists and a longer one for the
/// hero card.
const Map<SubscriptionCategory, ({String short, String long})> _builtIn = {
  SubscriptionCategory.entertainment: (
    short: 'Movies, streaming & video',
    long: 'Movies, TV series, streaming & live video',
  ),
  SubscriptionCategory.music: (short: 'Music, podcasts & audio', long: 'Music streaming, podcasts & audiobooks'),
  SubscriptionCategory.productivity: (
    short: 'Suites, AI & workspaces',
    long: 'Productivity suites, AI assistants & workspaces',
  ),
  SubscriptionCategory.cloud: (short: 'Storage & file backup', long: 'Cloud storage, file hosting & drive backup'),
  SubscriptionCategory.gaming: (short: 'Games & cloud passes', long: 'Game passes, consoles & cloud gaming'),
  SubscriptionCategory.design: (short: 'Creative & vector tools', long: 'Creative suites, vector & graphic design tools'),
  SubscriptionCategory.developer: (
    short: 'APIs, code & cloud hosting',
    long: 'Cloud hosting, APIs, code tools & repositories',
  ),
  SubscriptionCategory.utilities: (
    short: 'VPN & security utilities',
    long: 'VPNs, password managers & privacy utilities',
  ),
  SubscriptionCategory.finance: (short: 'Banking & investments', long: 'Banking, investing & personal finance trackers'),
  SubscriptionCategory.health: (short: 'Fitness & wellness', long: 'Fitness tracking, workout coaching & wellness'),
};

/// The grey line under a category's name. A custom category says how many subscriptions
/// use it ([usage]), or "Your category" when none do.
String categoryDescription(SubscriptionCategory category, {required int usage, bool long = false}) {
  final builtIn = _builtIn[category];
  if (builtIn != null) return long ? builtIn.long : builtIn.short;
  return usage == 0 ? 'Your category' : '$usage ${usage == 1 ? 'subscription' : 'subscriptions'}';
}
