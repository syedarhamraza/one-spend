import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../features/pro/presentation/pro_controller.dart';
import '../../features/pro/presentation/pro_gate.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/one_ui_toast.dart';

/// Settings › Appearance: the 3D effect for floating controls, and the two customisation studios.
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAppearance);
  }

  void _toggle3d(OneUIEffectsController effects) {
    HapticFeedback.selectionClick();
    effects.floating3dEffect = !effects.floating3dEffect;
  }

  void _reset(BuildContext context, OneUIEffectsController effects) {
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Reset appearance?',
      message: 'Turns off 3D effects and restores the default subscription card and detail styles.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Reset',
      confirmTextColor: OneUITheme.accentOrange,
      onConfirm: () {
        HapticFeedback.mediumImpact();
        effects
          ..floating3dEffect = false
          ..resetCardStyle()
          ..resetDetailStyle();
        OneUIToast.show(context, 'Appearance reset');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effects = OneUIEffectsController.instance;
    return OneUISubpage(
      title: 'Appearance',
      listenable: Listenable.merge([effects, ProController.instance]),
      builder: (context) => [
        OneUISection(
          title: 'Effects',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: '3D floating elements',
                subtitle: 'Raised glass look for the navigation bar, buttons and pills',
                trailing: OneUISwitch(value: effects.floating3dEffect, onChanged: (_) => _toggle3d(effects)),
                onTap: () => _toggle3d(effects),
              ),
            ],
          ),
        ),
        OneUISection(
          title: 'Customise',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Subscription cards',
                subtitle: 'Price, renewal badge and details shown on each card',
                trailing: ProGate.chip(),
                onTap: () => ProGate.run(context, () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.cardStudio);
                }),
              ),
              OneUIGroupItem(
                title: 'Subscription details',
                subtitle: 'Icons and highlights on the subscription page',
                trailing: ProGate.chip(),
                onTap: () => ProGate.run(context, () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.detailStudio);
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            OneUIGroupItem(
              title: 'Reset appearance',
              trailing: const SizedBox.shrink(),
              onTap: () => _reset(context, effects),
            ),
          ],
        ),
      ],
    );
  }
}
