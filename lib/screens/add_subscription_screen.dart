import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_brand_catalog.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_icon_picker_modal.dart';
import '../widgets/one_ui_toast.dart';
import 'one_ui_field_editor_screen.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscriptionToEdit;

  const AddSubscriptionScreen({
    super.key,
    this.subscriptionToEdit,
  });

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  late String _name;
  late double _price;
  late String _currency;
  late BillingCycle _billingCycle;
  late SubscriptionCategory _category;
  late DateTime _nextBillingDate;
  late Color _brandColor;
  late IconData _iconData;
  late String _paymentMethod;
  late int _reminderDays;
  late SubscriptionStatus _status;
  late String _notes;
  late String _accountUrl;
  String? _logoUrl;
  String? _brandPresetId;

  bool get isEditing => widget.subscriptionToEdit != null;

  @override
  void initState() {
    super.initState();
    final editSub = widget.subscriptionToEdit;
    if (editSub != null) {
      _name = editSub.name;
      _price = editSub.price;
      _currency = editSub.currency;
      _billingCycle = editSub.billingCycle;
      _category = editSub.category;
      _nextBillingDate = editSub.nextBillingDate;
      _brandColor = editSub.brandColor;
      _iconData = editSub.iconData;
      _paymentMethod = editSub.paymentMethod;
      _reminderDays = editSub.reminderDays;
      _status = editSub.status;
      _notes = editSub.notes;
      _accountUrl = editSub.accountUrl;
      _logoUrl = editSub.logoUrl;
      _brandPresetId = editSub.brandPresetId;
    } else {
      _name = '';
      _price = 0.0;
      _currency = SubscriptionStore.instance.currency;
      _billingCycle = BillingCycle.monthly;
      _category = SubscriptionCategory.entertainment;
      _nextBillingDate = DateTime.now().add(const Duration(days: 30));
      _brandColor = OneUITheme.accentBlue;
      _iconData = Icons.subscriptions_rounded;
      _paymentMethod = 'Samsung Pay (Visa •••• 9124)';
      _reminderDays = 2;
      _status = SubscriptionStatus.active;
      _notes = '';
      _accountUrl = '';
      _logoUrl = null;
      _brandPresetId = null;
    }
  }

  void _applyPreset(BrandPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _name = preset.name;
      _category = preset.category;
      _brandColor = preset.color;
      _iconData = preset.icon;
      _brandPresetId = preset.id;
      _logoUrl = preset.logoUrl;
      if (_accountUrl.isEmpty) {
        _accountUrl = preset.defaultUrl;
      }
      if (_price <= 0) {
        final catalogMatch = popularCatalog.where((s) => s.name.toLowerCase() == preset.name.toLowerCase()).firstOrNull;
        if (catalogMatch != null) {
          _price = catalogMatch.price;
          _billingCycle = catalogMatch.billingCycle;
        }
      }
    });
    OneUIToast.show(context, 'Applied ${preset.name} preset');
  }

  Future<void> _pickBrandIcon() async {
    final result = await OneUIIconPickerModal.show(
      context,
      currentColor: _brandColor,
      currentIcon: _iconData,
      currentLogoUrl: _logoUrl,
      currentPresetId: _brandPresetId,
    );
    if (!mounted || result == null) return;
    setState(() {
      _brandColor = result.brandColor;
      _iconData = result.iconData;
      _logoUrl = result.logoUrl;
      _brandPresetId = result.brandPresetId;
    });
  }

  Future<void> _editField<T>({
    required String title,
    String? subtitle,
    required FieldEditorType type,
    required T initialValue,
    required Function(T value) onApply,
    String? prefixText,
    String? hintText,
  }) async {
    final result = await OneUIFieldEditorScreen.open<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      type: type,
      initialValue: initialValue,
      prefixText: prefixText,
      hintText: hintText,
      currency: _currency,
    );

    if (result != null && mounted) {
      setState(() {
        onApply(result);
      });
    }
  }

  void _selectReminderDays() {
    HapticFeedback.lightImpact();
    const reminderOptions = [
      {'days': 0, 'label': 'On the day of renewal'},
      {'days': 1, 'label': '1 day before'},
      {'days': 2, 'label': '2 days before (Recommended)'},
      {'days': 3, 'label': '3 days before'},
      {'days': 5, 'label': '5 days before'},
      {'days': 7, 'label': '1 week before'},
      {'days': 14, 'label': '2 weeks before'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: OneUITheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Renewal Reminder Alert',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: OneUITheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: OneUITheme.surfacePill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: reminderOptions.map((opt) {
                    final days = opt['days'] as int;
                    final label = opt['label'] as String;
                    final isSelected = _reminderDays == days;

                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _reminderDays = days;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 22)
                            else
                              Icon(Icons.radio_button_unchecked_rounded,
                                  color: Colors.white.withValues(alpha: 0.25), size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveSubscription() {
    final name = _name.trim();
    if (name.isEmpty || _price <= 0) {
      OneUIToast.show(context, 'Please enter a valid service name and price');
      return;
    }

    final newSub = Subscription(
      id: widget.subscriptionToEdit?.id ?? Subscription.generateUniqueId('sub'),
      name: name,
      description: '${_category.label} subscription',
      price: _price,
      currency: _currency,
      billingCycle: _billingCycle,
      category: _category,
      brandColor: _brandColor,
      iconData: _iconData,
      nextBillingDate: _nextBillingDate,
      status: _status,
      paymentMethod: _paymentMethod.trim(),
      reminderDays: _reminderDays,
      notes: _notes.trim(),
      paymentHistory: widget.subscriptionToEdit?.paymentHistory ?? [],
      accountUrl: _accountUrl.trim(),
      logoUrl: _logoUrl,
      brandPresetId: _brandPresetId,
    );

    if (isEditing) {
      SubscriptionStore.instance.updateSubscription(newSub);
      OneUIToast.show(context, '${newSub.name} updated');
    } else {
      SubscriptionStore.instance.addSubscription(newSub);
      OneUIToast.show(context, '${newSub.name} added');
    }
    Navigator.pop(context, newSub);
  }

  Widget _buildCategoryIconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(_nextBillingDate);
    final canSave = _name.trim().isNotEmpty && _price > 0;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // One UI Signature Collapsible Header with Back Button
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: isEditing ? 'Edit subscription' : 'Add subscription',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Presets Quick Selector (when creating new)
                      if (!isEditing) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Popular Presets',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: OneUIBrandCatalog.presets.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final preset = OneUIBrandCatalog.presets[index];
                              final isSelected = _brandPresetId == preset.id ||
                                  _name.toLowerCase() == preset.name.toLowerCase();

                              return GestureDetector(
                                onTap: () => _applyPreset(preset),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? OneUITheme.surfacePillActive : OneUITheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: isSelected
                                          ? OneUITheme.accentBlue
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: isSelected ? 1.2 : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OneUIBrandIcon(
                                        brandPresetId: preset.id,
                                        name: preset.name,
                                        brandColor: preset.color,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        preset.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? OneUITheme.accentBlue : OneUITheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Top Live Hero Card Preview
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Interactive Brand Logo Squircle
                            GestureDetector(
                              onTap: _pickBrandIcon,
                              child: Stack(
                                children: [
                                  OneUIBrandIcon(
                                    name: _name.isNotEmpty ? _name : 'Service',
                                    brandColor: _brandColor,
                                    iconData: _iconData,
                                    logoUrl: _logoUrl,
                                    brandPresetId: _brandPresetId,
                                    size: 58,
                                    borderRadius: 18,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: OneUITheme.surfaceCardHighlight,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name.isNotEmpty ? '$_name Plan' : 'New Subscription',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: OneUITheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_currency${_price.toStringAsFixed(2)} • ${_billingCycle.label}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section 1: Plan & Billing (Grouped One UI Card with Subpages)
                      OneUISection(
                        title: 'Plan & Billing',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.badge_outlined, OneUITheme.accentBlue),
                              title: 'Service name',
                              subtitle: _name.isNotEmpty ? _name : 'Tap to enter name',
                              subtitleColor: _name.isNotEmpty
                                  ? OneUITheme.textPrimary
                                  : OneUITheme.textSecondary.withValues(alpha: 0.6),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<String>(
                                title: 'Service name',
                                type: FieldEditorType.text,
                                initialValue: _name,
                                hintText: 'e.g. Netflix, Spotify',
                                onApply: (val) {
                                  _name = val;
                                  final match = OneUIBrandCatalog.findPreset(val);
                                  if (match != null && _brandPresetId == null) {
                                    _brandPresetId = match.id;
                                    _brandColor = match.color;
                                    _iconData = match.icon;
                                    _category = match.category;
                                    if (_accountUrl.isEmpty) _accountUrl = match.defaultUrl;
                                  }
                                },
                              ),
                            ),
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.attach_money_rounded, OneUITheme.accentGreen),
                              title: 'Price / Cost',
                              subtitle: '$_currency${_price.toStringAsFixed(2)} / ${_billingCycle.label}',
                              subtitleColor: OneUITheme.accentGreen,
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<double>(
                                title: 'Price / Cost',
                                type: FieldEditorType.number,
                                initialValue: _price,
                                onApply: (val) => _price = val,
                              ),
                            ),
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.repeat_rounded, OneUITheme.accentPurple),
                              title: 'Billing cycle',
                              subtitle: '${_billingCycle.label} (${_billingCycle.occurrencesPerYear}x / year)',
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<BillingCycle>(
                                title: 'Billing cycle',
                                type: FieldEditorType.billingCycle,
                                initialValue: _billingCycle,
                                onApply: (val) => _billingCycle = val,
                              ),
                            ),
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.calendar_month_rounded, OneUITheme.accentTeal),
                              title: 'First renewal date',
                              subtitle: formattedDate,
                              subtitleColor: OneUITheme.accentBlue,
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<DateTime>(
                                title: 'Renewal date',
                                type: FieldEditorType.date,
                                initialValue: _nextBillingDate,
                                onApply: (val) => _nextBillingDate = val,
                              ),
                            ),
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.link_rounded, OneUITheme.accentBlue),
                              title: 'Account / Website URL',
                              subtitle: _accountUrl.isNotEmpty ? _accountUrl : 'Optional website or login URL',
                              subtitleColor: _accountUrl.isNotEmpty
                                  ? OneUITheme.accentBlue
                                  : OneUITheme.textSecondary.withValues(alpha: 0.6),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<String>(
                                title: 'Account URL',
                                type: FieldEditorType.text,
                                initialValue: _accountUrl,
                                hintText: 'https://example.com/account',
                                onApply: (val) => _accountUrl = val,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section 2: Payment & Reminders
                      OneUISection(
                        title: 'Payment & Reminders',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(_category.icon, OneUITheme.accentPurple),
                              title: 'Category',
                              subtitle: _category.label,
                              subtitleColor: OneUITheme.textPrimary,
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<SubscriptionCategory>(
                                title: 'Category',
                                type: FieldEditorType.category,
                                initialValue: _category,
                                onApply: (val) => _category = val,
                              ),
                            ),
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.payment_rounded, OneUITheme.accentAmber),
                              title: 'Payment method',
                              subtitle: _paymentMethod,
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<String>(
                                title: 'Payment method',
                                type: FieldEditorType.text,
                                initialValue: _paymentMethod,
                                onApply: (val) => _paymentMethod = val,
                              ),
                            ),
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.notifications_active_rounded, OneUITheme.accentTeal),
                              title: 'Renewal notification',
                              subtitle: _reminderDays == 0
                                  ? 'On renewal day'
                                  : 'Alert $_reminderDays days before',
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: _selectReminderDays,
                            ),
                          ],
                        ),
                      ),

                      // Section 3: Notes
                      OneUISection(
                        title: 'Notes',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: _buildCategoryIconBadge(Icons.notes_rounded, Colors.white70),
                              title: 'Plan notes',
                              subtitle: _notes.isNotEmpty ? _notes : 'Tap to add optional notes or terms...',
                              subtitleColor: _notes.isNotEmpty
                                  ? OneUITheme.textSecondary
                                  : OneUITheme.textSecondary.withValues(alpha: 0.6),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                              onTap: () => _editField<String>(
                                title: 'Plan notes',
                                type: FieldEditorType.notes,
                                initialValue: _notes,
                                onApply: (val) => _notes = val,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Standardized Floating "Cancel | Save" Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 20,
            child: Center(
              child: OneUIFloatingCancelSavePill(
                onCancel: () => Navigator.pop(context),
                onSave: _saveSubscription,
                canSave: canSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
