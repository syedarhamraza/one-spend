import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/one_ui_toast.dart';

/// Opens [url] in the matching app (browser, mail…); shows a toast if nothing can handle it.
Future<void> openExternalLink(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) OneUIToast.show(context, 'Couldn\'t open the link');
}

/// Opens a web page in an in-app browser tab (Chrome Custom Tabs) over One Spend, so Back
/// returns straight to the app. Falls back to the browser app; shows a toast if neither works.
Future<void> openInAppBrowser(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) return openExternalLink(context, url);
}

/// Opens [url], or [fallbackUrl] when no app handles it (e.g. a `market://` link without
/// the Play Store).
Future<void> openExternalLinkOr(BuildContext context, String url, String fallbackUrl) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) return openExternalLink(context, fallbackUrl);
}

/// A `mailto:` URL with an optional subject.
String mailtoUrl(String email, {String? subject, String? body}) {
  final query = [
    if (subject != null) 'subject=${Uri.encodeComponent(subject)}',
    if (body != null) 'body=${Uri.encodeComponent(body)}',
  ];
  return Uri(scheme: 'mailto', path: email, query: query.isEmpty ? null : query.join('&')).toString();
}
