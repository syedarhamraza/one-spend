import 'package:flutter/widgets.dart';

import '../../../widgets/one_ui_subpage.dart';
import 'pro_controller.dart';
import 'pro_screen.dart';

/// The one way to put a feature behind OneSpend Pro.
class ProGate {
  const ProGate._();

  /// Runs [action] with Pro; otherwise opens the OneSpend Pro page.
  static void run(BuildContext context, VoidCallback action) {
    if (ProController.instance.isPro) {
      action();
    } else {
      ProScreen.open(context);
    }
  }

  /// Trailing chip for a Pro-only row: the Pro chip while locked, [unlocked] (or nothing) after.
  static Widget chip({Widget unlocked = const SizedBox.shrink()}) =>
      ProController.instance.isPro ? unlocked : const OneUIProChip();
}
