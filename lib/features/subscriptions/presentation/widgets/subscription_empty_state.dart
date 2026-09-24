import 'package:flutter/material.dart';
import '../../../../theme/one_ui_theme.dart';

/// Reusable Samsung One UI Empty State for Subscriptions List & Search
class SubscriptionEmptyState extends StatelessWidget {
  final VoidCallback onReset;
  final String title;
  final String message;

  const SubscriptionEmptyState({
    super.key,
    required this.onReset,
    this.title = 'No subscriptions found',
    this.message = 'Try adjusting your search or category filter',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: OneUITheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OneUITheme.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: onReset,
            child: const Text('Reset filters', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
