import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/subscription.dart';
import '../utils/one_ui_brand_catalog.dart';

/// Samsung One UI Squircle Brand & Service Icon
/// - Renders bundled vector SVG logo if matching brand exists in assets
/// - Renders company logo if image URL is available (with safe inner padding & contain fit)
/// - Renders curated brand preset monogram / icon
/// - Renders dynamic monogram for custom services
/// - Uses smooth rounded squircle geometry with subtle rim border
class OneUIBrandIcon extends StatelessWidget {
  final Subscription? subscription;
  final String? name;
  final Color? brandColor;
  final IconData? iconData;
  final String? logoUrl;
  final String? brandPresetId;
  final double size;
  final double? borderRadius;

  const OneUIBrandIcon({
    super.key,
    this.subscription,
    this.name,
    this.brandColor,
    this.iconData,
    this.logoUrl,
    this.brandPresetId,
    this.size = 44,
    this.borderRadius,
  });

  static const Map<String, String> _brandSvgMap = {
    'netflix': 'assets/logos/brands/netflix.svg',
    'spotify': 'assets/logos/brands/spotify.svg',
    'youtube': 'assets/logos/brands/youtube.svg',
    'youtubepremium': 'assets/logos/brands/youtube.svg',
    'apple': 'assets/logos/brands/apple.svg',
    'applemusic': 'assets/logos/brands/applemusic.svg',
    'appletv': 'assets/logos/brands/appletv.svg',
    'appletvplus': 'assets/logos/brands/appletv.svg',
    'appleone': 'assets/logos/brands/apple.svg',
    'icloud': 'assets/logos/brands/icloud.svg',
    'github': 'assets/logos/brands/github.svg',
    'githubcopilot': 'assets/logos/brands/github.svg',
    'notion': 'assets/logos/brands/notion.svg',
    'figma': 'assets/logos/brands/figma.svg',
    'google': 'assets/logos/brands/google.svg',
    'googleone': 'assets/logos/brands/google.svg',
    'googledrive': 'assets/logos/brands/googledrive.svg',
    'googlecloud': 'assets/logos/brands/googlecloud.svg',
    'crunchyroll': 'assets/logos/brands/crunchyroll.svg',
    'duolingo': 'assets/logos/brands/duolingo.svg',
    'dropbox': 'assets/logos/brands/dropbox.svg',
    'discord': 'assets/logos/brands/discord.svg',
    'discordnitro': 'assets/logos/brands/discord.svg',
    'playstation': 'assets/logos/brands/playstation.svg',
    'playstationplus': 'assets/logos/brands/playstation.svg',
    'twitch': 'assets/logos/brands/twitch.svg',
    'patreon': 'assets/logos/brands/patreon.svg',
    'soundcloud': 'assets/logos/brands/soundcloud.svg',
    'medium': 'assets/logos/brands/medium.svg',
    'substack': 'assets/logos/brands/substack.svg',
    'x': 'assets/logos/brands/x.svg',
    'twitter': 'assets/logos/brands/x.svg',
    'proton': 'assets/logos/brands/proton.svg',
    'protonvpn': 'assets/logos/brands/proton.svg',
    'protonmail': 'assets/logos/brands/proton.svg',
    '1password': 'assets/logos/brands/1password.svg',
    'bitwarden': 'assets/logos/brands/bitwarden.svg',
    'evernote': 'assets/logos/brands/evernote.svg',
    'telegram': 'assets/logos/brands/telegram.svg',
    'telegrampremium': 'assets/logos/brands/telegram.svg',
    'nordvpn': 'assets/logos/brands/nordvpn.svg',
    'expressvpn': 'assets/logos/brands/expressvpn.svg',
    'max': 'assets/logos/brands/max.svg',
    'hbomax': 'assets/logos/brands/hbomax.svg',
    'coursera': 'assets/logos/brands/coursera.svg',
    'udemy': 'assets/logos/brands/udemy.svg',
    'strava': 'assets/logos/brands/strava.svg',
    'fitbit': 'assets/logos/brands/fitbit.svg',
    'paramountplus': 'assets/logos/brands/paramountplus.svg',
    'deezer': 'assets/logos/brands/deezer.svg',
    'tidal': 'assets/logos/brands/tidal.svg',
    'audible': 'assets/logos/brands/audible.svg',
    'googleworkspace': 'assets/logos/brands/google.svg',
    'nintendo': 'assets/logos/brands/nintendo.svg',
    'nintendoswitch': 'assets/logos/brands/nintendoswitch.svg',
    'nintendoswitchonline': 'assets/logos/brands/nintendoswitch.svg',
    'xbox': 'assets/logos/brands/xbox.svg',
    'xboxgamepass': 'assets/logos/brands/xbox.svg',
    'microsoft': 'assets/logos/brands/microsoft.svg',
    'microsoft365': 'assets/logos/brands/microsoft.svg',
    'canva': 'assets/logos/brands/canva.svg',
    'canvapro': 'assets/logos/brands/canva.svg',
    'adobe': 'assets/logos/brands/adobe.svg',
    'adobecreativecloud': 'assets/logos/brands/adobecreativecloud.svg',
    'adobecc': 'assets/logos/brands/adobe.svg',
    'slack': 'assets/logos/brands/slack.svg',
    'claude': 'assets/logos/brands/claude.svg',
    'claudepro': 'assets/logos/brands/claude.svg',
    'chatgpt': 'assets/logos/brands/openai.svg',
    'chatgptplus': 'assets/logos/brands/openai.svg',
    'openai': 'assets/logos/brands/openai.svg',
    'amazon': 'assets/logos/brands/amazon.svg',
    'amazonprime': 'assets/logos/brands/amazonprime.svg',
    'disney': 'assets/logos/brands/disneyplus.svg',
    'disneyplus': 'assets/logos/brands/disneyplus.svg',
    'dplus': 'assets/logos/brands/disneyplus.svg',
    'd': 'assets/logos/brands/disneyplus.svg',
  };

  static final RegExp _alphanumericRegex = RegExp(r'[^a-z0-9]');

  static String? resolveBrandSvg(String name, [String? presetId]) {
    final lowerName = name.toLowerCase().replaceAll(_alphanumericRegex, '');
    final lowerId = presetId?.toLowerCase().replaceAll(_alphanumericRegex, '') ?? '';
    final candidates = [lowerId, lowerName];
    for (final key in candidates) {
      if (key.isEmpty) continue;
      if (_brandSvgMap.containsKey(key)) {
        return _brandSvgMap[key];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subName = subscription?.name ?? name ?? 'Service';
    final effectiveLogoUrl = subscription?.logoUrl ?? logoUrl;
    final effectivePresetId = subscription?.brandPresetId ?? brandPresetId;
    final preset = OneUIBrandCatalog.findById(effectivePresetId) ?? OneUIBrandCatalog.findPreset(subName);

    final effectiveColor = subscription?.brandColor ??
        brandColor ??
        (preset != null ? preset.color : OneUIBrandCatalog.getMonogramColor(subName));

    final effectiveRadius = borderRadius ?? (size * 0.32);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _buildInnerContent(context, subName, preset, effectiveLogoUrl, effectivePresetId),
    );
  }

  Widget _buildInnerContent(
    BuildContext context,
    String subName,
    BrandPreset? preset,
    String? effectiveLogoUrl,
    String? effectivePresetId,
  ) {
    // 1. Check for bundled SVG asset first (instant, zero network lag, vector sharp)
    final svgAsset = resolveBrandSvg(subName, effectivePresetId);
    if (svgAsset != null) {
      return Center(
        child: SvgPicture.asset(
          svgAsset,
          width: size * 0.54,
          height: size * 0.54,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            preset?.textColor ?? Colors.white,
            BlendMode.srcIn,
          ),
          placeholderBuilder: (context) => _buildFallback(subName, preset),
        ),
      );
    }

    // 2. Network image logo if provided (downsampled to device resolution to prevent raster spikes)
    if (effectiveLogoUrl != null && effectiveLogoUrl.isNotEmpty) {
      final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
      final cacheDim = (size * pixelRatio).round();
      return Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: Image.network(
          effectiveLogoUrl,
          fit: BoxFit.contain,
          cacheWidth: cacheDim,
          cacheHeight: cacheDim,
          errorBuilder: (context, error, stackTrace) => _buildFallback(subName, preset),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback(subName, preset);
          },
        ),
      );
    }

    return _buildFallback(subName, preset);
  }

  Widget _buildFallback(String subName, BrandPreset? preset) {
    // 2. Curated brand preset monogram or icon
    if (preset != null && preset.monogram.isNotEmpty && preset.monogram != '') {
      return Center(
        child: Text(
          preset.monogram,
          style: TextStyle(
            color: preset.textColor,
            fontSize: size * 0.40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    // 3. Subscription IconData if explicit
    final effectiveIcon = subscription?.iconData ?? iconData ?? preset?.icon;
    if (effectiveIcon != null && effectiveIcon != Icons.subscriptions_rounded) {
      return Icon(
        effectiveIcon,
        color: Colors.white,
        size: size * 0.52,
      );
    }

    // 4. Dynamic styled monogram
    final monogram = OneUIBrandCatalog.getMonogram(subName);
    return Center(
      child: Text(
        monogram,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
