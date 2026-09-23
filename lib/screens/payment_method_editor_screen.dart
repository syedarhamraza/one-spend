import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_toast.dart';
import '../widgets/one_ui_payment_brand_icon.dart';

/// Dedicated Samsung One UI Payment Method Editor Subpage.
/// Allows adding or editing a tracked payment method with live card preview,
/// nickname, brand, masked digits, expiry date, custom tint, and default toggle.
class PaymentMethodEditorScreen extends StatefulWidget {
  final PaymentMethod? initialMethod;

  const PaymentMethodEditorScreen({
    super.key,
    this.initialMethod,
  });

  static Future<PaymentMethod?> open(
    BuildContext context, {
    PaymentMethod? method,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodEditorScreen(initialMethod: method),
      ),
    );
  }

  @override
  State<PaymentMethodEditorScreen> createState() => _PaymentMethodEditorScreenState();
}

class _PaymentMethodEditorScreenState extends State<PaymentMethodEditorScreen> {
  late String _id;
  late TextEditingController _nicknameController;
  late TextEditingController _last4Controller;
  late TextEditingController _expiryController;
  late TextEditingController _statementController;
  late PaymentMethodType _type;
  late CardBrand _brand;
  late Color _cardColor;
  late bool _isDefault;

  static const List<Color> _cardColors = [
    Color(0xFF1E2638), // Dark Navy
    Color(0xFF8B0000), // Crimson / Standard Chartered
    Color(0xFF004D40), // Dark Green / Meezan
    Color(0xFF1428A0), // Samsung Blue
    Color(0xFF2C3440), // Classic Slate
    Color(0xFF3E2723), // Deep Bronze
    Color(0xFF4A148C), // Royal Purple
    Color(0xFF1A1A1A), // Matte Black
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.initialMethod;
    _id = m?.id ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';
    _nicknameController = TextEditingController(text: m?.nickname ?? '');
    _last4Controller = TextEditingController(text: m?.last4 ?? '');
    _expiryController = TextEditingController(text: m?.expiryDate ?? '');
    _statementController = TextEditingController(text: m?.statementDay?.toString() ?? '');
    _type = m?.type ?? PaymentMethodType.creditCard;
    _brand = m?.brand ?? CardBrand.visa;
    _cardColor = m?.cardColor ?? _cardColors[0];
    _isDefault = m?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _last4Controller.dispose();
    _expiryController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  void _save() {
    final nickname = _nicknameController.text.trim();
    final last4 = _last4Controller.text.trim();
    final expiry = _expiryController.text.trim();
    final statementDay = int.tryParse(_statementController.text.trim());

    if (nickname.isEmpty && last4.isEmpty) {
      OneUIToast.show(context, 'Please enter a nickname or last 4 digits');
      return;
    }

    HapticFeedback.mediumImpact();
    final result = PaymentMethod(
      id: _id,
      nickname: nickname.isNotEmpty ? nickname : '${_brand.label} Card',
      type: _type,
      brand: _brand,
      last4: last4,
      expiryDate: expiry,
      cardColor: _cardColor,
      isDefault: _isDefault,
      statementDay: statementDay,
    );

    final store = SubscriptionStore.instance;
    if (widget.initialMethod == null) {
      store.addPaymentMethod(result);
    } else {
      store.updatePaymentMethod(result);
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMethod != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: isEditing ? 'Edit card' : 'Add card',
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
                      // Top Live Card Mockup Visualizer
                      _buildLiveCardMockup(),
                      const SizedBox(height: 18),

                      // Card Color Swatches
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Card Color Tint',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _cardColors.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final color = _cardColors[index];
                                  final isSelected = _cardColor.toARGB32() == color.toARGB32();

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _cardColor = color);
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 1: Card Identification & Nickname
                      OneUISection(
                        title: 'Card Details',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Nickname / Alias',
                              subtitle: _nicknameController.text.isNotEmpty
                                  ? _nicknameController.text
                                  : 'Tap to enter (e.g. Personal Meezan, Salary)',
                              trailing: SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _nicknameController,
                                  textAlign: TextAlign.end,
                                  onChanged: (val) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'e.g. Salary Card',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: OneUITheme.textSecondary,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                            OneUIGroupItem(
                              title: 'Last 4 digits',
                              subtitle: _last4Controller.text.isNotEmpty
                                  ? '•••• ${_last4Controller.text}'
                                  : 'Optional (numbers only)',
                              trailing: SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _last4Controller,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  textAlign: TextAlign.end,
                                  onChanged: (val) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                    color: OneUITheme.accentBlue,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: '1234',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      letterSpacing: 0,
                                      color: OneUITheme.textSecondary,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                            OneUIGroupItem(
                              title: 'Expiry date',
                              subtitle: _expiryController.text.isNotEmpty
                                  ? 'MM/YY: ${_expiryController.text}'
                                  : 'Format MM/YY (e.g. 12/28)',
                              trailing: SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.datetime,
                                  maxLength: 5,
                                  textAlign: TextAlign.end,
                                  onChanged: (val) {
                                    if (val.length == 2 && !_expiryController.text.contains('/')) {
                                      _expiryController.text = '$val/';
                                      _expiryController.selection = TextSelection.fromPosition(
                                        TextPosition(offset: _expiryController.text.length),
                                      );
                                    }
                                    setState(() {});
                                  },
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: OneUITheme.accentBlue,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: '12/28',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: OneUITheme.textSecondary,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Method Type & Brand Selection
                      OneUISection(
                        title: 'Card Type & Brand',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  title: 'Payment method type',
                                  subtitle: _type.label,
                                  trailing: DropdownButtonHideUnderline(
                                    child: DropdownButton<PaymentMethodType>(
                                      value: _type,
                                      dropdownColor: OneUITheme.cardColor,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: OneUITheme.accentBlue,
                                      ),
                                      items: PaymentMethodType.values.map((t) {
                                        return DropdownMenuItem(
                                          value: t,
                                          child: Text(t.label),
                                        );
                                      }).toList(),
                                      onChanged: (newType) {
                                        if (newType != null) {
                                          setState(() => _type = newType);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: OneUITheme.cardColor,
                                borderRadius: OneUITheme.cardBorderRadius,
                                border: OneUITheme.cardBorder,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Network / Provider',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        _brand.label,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: OneUITheme.accentBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 52,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: CardBrand.values.length,
                                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        final b = CardBrand.values[index];
                                        final isSelected = b == _brand;
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _brand = b;
                                              if (b == CardBrand.applePay ||
                                                  b == CardBrand.googlePay ||
                                                  b == CardBrand.samsungPay ||
                                                  b == CardBrand.paypal ||
                                                  b == CardBrand.alipay ||
                                                  b == CardBrand.wechatPay ||
                                                  b == CardBrand.amazonPay) {
                                                _type = PaymentMethodType.digitalWallet;
                                              } else if (b == CardBrand.bank) {
                                                _type = PaymentMethodType.bankTransfer;
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? OneUITheme.accentBlue.withValues(alpha: 0.16)
                                                  : Colors.white.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isSelected
                                                    ? OneUITheme.accentBlue
                                                    : Colors.white.withValues(alpha: 0.12),
                                                width: isSelected ? 1.8 : 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                OneUIPaymentBrandIcon(brand: b, width: 36, height: 24),
                                                const SizedBox(width: 8),
                                                Text(
                                                  b.label,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Preferences
                      OneUISection(
                        title: 'Preferences',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Default payment method',
                              subtitle: 'Auto-select when adding new subscriptions',
                              trailing: Switch.adaptive(
                                value: _isDefault,
                                activeTrackColor: OneUITheme.accentBlue,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isDefault = val);
                                },
                              ),
                            ),
                            OneUIGroupItem(
                              title: 'Statement due day (optional)',
                              subtitle: _statementController.text.isNotEmpty
                                  ? 'Day ${_statementController.text} of every month'
                                  : 'Closing / bill due date (1-31)',
                              trailing: SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _statementController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 2,
                                  textAlign: TextAlign.end,
                                  onChanged: (val) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.accentBlue,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: '15',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: OneUITheme.textSecondary,
                                    ),
                                    isDense: true,
                                  ),
                                ),
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

          // Floating Cancel | Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: _save,
                    saveLabel: 'Save',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCardMockup() {
    final nickname = _nicknameController.text.trim();
    final last4 = _last4Controller.text.trim();
    final expiry = _expiryController.text.trim();

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Brand Icon & Default Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  OneUIPaymentBrandIcon(
                    brand: _brand,
                    width: 44,
                    height: 28,
                    showShadow: true,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _brand.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              if (_isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),

          // Middle: EMV Chip & Masked digits
          Row(
            children: [
              Container(
                width: 34,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                last4.isNotEmpty ? '•••• •••• •••• $last4' : '•••• •••• •••• ••••',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),

          // Bottom Row: Nickname & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nickname.isNotEmpty ? nickname : 'Card Nickname',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                expiry.isNotEmpty ? 'EXP $expiry' : 'EXP MM/YY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
