import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';

/// Settings › About › Developer: who made OneSpend and how to reach them.
/// Values come from [AuthorInfo]; empty ones are hidden.
class AuthorScreen extends StatelessWidget {
  const AuthorScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAuthor);
  }

  /// "github.com/you" style label for a URL.
  static String _shortUrl(String url) => url.replaceFirst(RegExp(r'^https?://(www\.)?'), '');

  @override
  Widget build(BuildContext context) {
    const openIcon = Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.textSecondary);
    OneUIGroupItem link(IconData icon, Color color, String title, String value, String url) => OneUIGroupItem(
          leading: OneUIIconBadge(icon, color),
          title: title,
          subtitle: value,
          subtitleColor: OneUITheme.textSecondary,
          trailing: openIcon,
          onTap: () => openExternalLink(context, url),
        );

    final contact = [
      if (AuthorInfo.email.isNotEmpty)
        link(Icons.mail_rounded, OneUITheme.accentBlue, 'Email', AuthorInfo.email,
            mailtoUrl(AuthorInfo.email, subject: 'Hello from OneSpend')),
      if (AuthorInfo.linkedInUrl.isNotEmpty)
        link(Icons.work_rounded, const Color(0xFF0A66C2), 'LinkedIn', _shortUrl(AuthorInfo.linkedInUrl),
            AuthorInfo.linkedInUrl),
      if (AuthorInfo.websiteUrl.isNotEmpty)
        link(Icons.language_rounded, OneUITheme.accentTeal, 'Website', _shortUrl(AuthorInfo.websiteUrl),
            AuthorInfo.websiteUrl),
    ];
    final code = [
      if (AuthorInfo.githubUrl.isNotEmpty)
        link(Icons.code_rounded, OneUITheme.accentPurple, 'GitHub', '@${AuthorInfo.githubUsername}',
            AuthorInfo.githubUrl),
      link(Icons.folder_open_rounded, OneUITheme.accentGreen, 'OneSpend source code',
          _shortUrl(AppInfo.repositoryUrl), AppInfo.repositoryUrl),
    ];

    return OneUISubpage(
      title: 'Developer',
      builder: (context) => [
        const SizedBox(height: 14),
        Center(child: _avatar()),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            AuthorInfo.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: OneUITheme.textPrimary),
          ),
        ),
        if (AuthorInfo.role.isNotEmpty || AuthorInfo.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              [AuthorInfo.role, AuthorInfo.location].where((s) => s.isNotEmpty).join(' · '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: OneUITheme.textSecondary),
            ),
          ),
        ],
        if (AuthorInfo.bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              AuthorInfo.bio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textPrimary),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (contact.isNotEmpty)
          OneUISection(title: 'Contact', child: OneUIGroupCard(margin: EdgeInsets.zero, items: contact)),
        OneUISection(title: 'Code', child: OneUIGroupCard(margin: EdgeInsets.zero, items: code)),
      ],
    );
  }

  Widget _avatar() {
    const size = 104.0;
    if (AuthorInfo.photoAsset.isNotEmpty) {
      return ClipOval(child: Image.asset(AuthorInfo.photoAsset, width: size, height: size, fit: BoxFit.cover));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OneUITheme.accentBlue, OneUITheme.accentPurple],
        ),
      ),
      child: Text(
        AuthorInfo.initials,
        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
