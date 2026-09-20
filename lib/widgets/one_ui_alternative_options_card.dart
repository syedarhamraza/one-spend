import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIAlternativeAction {
  final String title;
  final VoidCallback onTap;

  const OneUIAlternativeAction({
    required this.title,
    required this.onTap,
  });
}

class OneUIAlternativeOptionsCard extends StatelessWidget {
  final String title;
  final List<OneUIAlternativeAction> actions;

  const OneUIAlternativeOptionsCard({
    super.key,
    this.title = 'Looking for something else?',
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1728), // Deep Samsung One UI Navy
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: OneUITheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...actions.map((act) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: act.onTap,
                    child: Text(
                      act.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: OneUITheme.accentBlue, // Vibrant blue link color matching Screenshot 1
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
