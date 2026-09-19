import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIFloatingActionBarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const OneUIFloatingActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class OneUIFloatingActionBar extends StatelessWidget {
  final List<OneUIFloatingActionBarItem> items;

  const OneUIFloatingActionBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          height: 60,
          decoration: BoxDecoration(
            color: OneUITheme.floatingColor,
            borderRadius: BorderRadius.circular(34),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(26),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: item.color ?? OneUITheme.textPrimary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: item.color ?? OneUITheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
