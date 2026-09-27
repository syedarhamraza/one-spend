import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_switch.dart';
import '../widgets/one_ui_toast.dart';

/// Helper to convert a Color to an uppercase 6-character hex string (e.g. #1E2638).
String _colorToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Curated palette of 12 distinct card tints.
const List<Color> _curatedCardColors = [
  Color(0xFF1E2638), // Navy Slate
  Color(0xFF1428A0), // Samsung Blue
  Color(0xFF8B0000), // Crimson
  Color(0xFF004D40), // Emerald Green
  Color(0xFF2C3440), // Classic Graphite
  Color(0xFF3E2723), // Deep Bronze
  Color(0xFF4A148C), // Royal Purple
  Color(0xFF1A1A1A), // Matte Black
  Color(0xFF006FCF), // Cobalt Blue
  Color(0xFF00796B), // Deep Teal
  Color(0xFFC2185B), // Berry Pink
  Color(0xFF455A64), // Blue Grey
];

/// Dedicated Samsung One UI Payment Method Editor Screen.
/// Follows One UI design principles with group cards, dedicated subpages for all options,
/// OneUISwitch for toggles, and a realistic flat credit card mockup at the top.
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
  late String _nickname;
  late String _last4;
  late String _expiry;
  int? _statementDay;
  late PaymentMethodType _type;
  late CardBrand _brand;
  late Color _cardColor;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMethod;
    _id = m?.id ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';
    _nickname = m?.nickname ?? '';
    _last4 = m?.last4 ?? '';
    _expiry = m?.expiryDate ?? '';
    _statementDay = m?.statementDay;
    _type = m?.type ?? PaymentMethodType.creditCard;
    _brand = m?.brand ?? CardBrand.visa;
    _cardColor = m?.cardColor ?? _curatedCardColors[0];
    _isDefault = m?.isDefault ?? false;
  }

  void _save() {
    final trimmedNickname = _nickname.trim();
    final trimmedLast4 = _last4.trim();
    final trimmedExpiry = _expiry.trim();

    if (trimmedNickname.isEmpty && trimmedLast4.isEmpty) {
      OneUIToast.show(context, 'Please enter a nickname or last 4 digits');
      return;
    }

    if (trimmedLast4.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(trimmedLast4)) {
      OneUIToast.show(context, 'Last 4 digits must contain exactly 4 numbers');
      return;
    }

    if (trimmedExpiry.isNotEmpty) {
      final parts = trimmedExpiry.split('/');
      if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
        OneUIToast.show(context, 'Expiry must be in MM/YY format');
        return;
      }
      final month = int.tryParse(parts[0]);
      if (month == null || month < 1 || month > 12) {
        OneUIToast.show(context, 'Expiry month must be between 01 and 12');
        return;
      }
    }

    if (_statementDay != null && (_statementDay! < 1 || _statementDay! > 31)) {
      OneUIToast.show(context, 'Statement day must be between 1 and 31');
      return;
    }

    HapticFeedback.mediumImpact();
    final result = PaymentMethod(
      id: _id,
      nickname: trimmedNickname.isNotEmpty ? trimmedNickname : '${_brand.label} Card',
      type: _type,
      brand: _brand,
      last4: trimmedLast4,
      expiryDate: trimmedExpiry,
      cardColorValue: _cardColor.toARGB32(),
      isDefault: _isDefault,
      statementDay: _statementDay,
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
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Collapsible Header
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: isEditing ? 'Edit card' : 'Add card',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Realistic Flat Credit Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RealisticFlatCardMockup(
                          cardColor: _cardColor,
                          brand: _brand,
                          nickname: _nickname,
                          last4: _last4,
                          expiry: _expiry,
                          isDefault: _isDefault,
                        ),
                      ),

                      // Section 1: Card Appearance
                      OneUISection(
                        title: 'Card appearance',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: 'Card color tint',
                              subtitle: _colorToHex(_cardColor),
                              subtitleColor: OneUITheme.accentBlue,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newColor = await Navigator.push<Color>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardColorPickerSubpage(
                                      initialColor: _cardColor,
                                      brand: _brand,
                                      nickname: _nickname,
                                      last4: _last4,
                                      expiry: _expiry,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newColor != null) {
                                  setState(() => _cardColor = newColor);
                                }
                              },
                            ),
                            OneUIGroupItem(
                              leading: OneUIPaymentBrandIcon(
                                brand: _brand,
                                width: 34,
                                height: 22,
                              ),
                              title: 'Card network / Provider',
                              subtitle: _brand.label,
                              subtitleColor: OneUITheme.accentBlue,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newBrand = await Navigator.push<CardBrand>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardBrandPickerSubpage(
                                      initialBrand: _brand,
                                      cardColor: _cardColor,
                                      nickname: _nickname,
                                      last4: _last4,
                                      expiry: _expiry,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newBrand != null) {
                                  setState(() {
                                    _brand = newBrand;
                                    // Auto-adjust type for digital wallets
                                    if (newBrand == CardBrand.applePay ||
                                        newBrand == CardBrand.googlePay ||
                                        newBrand == CardBrand.samsungPay ||
                                        newBrand == CardBrand.paypal ||
                                        newBrand == CardBrand.skrill ||
                                        newBrand == CardBrand.alipay ||
                                        newBrand == CardBrand.wechatPay) {
                                      _type = PaymentMethodType.digitalWallet;
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Card Details
                      OneUISection(
                        title: 'Card details',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Card nickname',
                              subtitle: _nickname.isNotEmpty
                                  ? _nickname
                                  : 'Tap to enter (e.g. Salary, Personal)',
                              subtitleColor: _nickname.isNotEmpty
                                  ? OneUITheme.accentBlue
                                  : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newNickname = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardNicknameEditorSubpage(
                                      initialNickname: _nickname,
                                      cardColor: _cardColor,
                                      brand: _brand,
                                      last4: _last4,
                                      expiry: _expiry,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newNickname != null) {
                                  setState(() => _nickname = newNickname);
                                }
                              },
                            ),
                            OneUIGroupItem(
                              title: 'Last 4 digits',
                              subtitle: _last4.isNotEmpty
                                  ? '•••• $_last4'
                                  : 'Optional (e.g. 4242)',
                              subtitleColor: _last4.isNotEmpty
                                  ? OneUITheme.accentBlue
                                  : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newLast4 = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardLast4EditorSubpage(
                                      initialLast4: _last4,
                                      cardColor: _cardColor,
                                      brand: _brand,
                                      nickname: _nickname,
                                      expiry: _expiry,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newLast4 != null) {
                                  setState(() => _last4 = newLast4);
                                }
                              },
                            ),
                            OneUIGroupItem(
                              title: 'Expiry date',
                              subtitle: _expiry.isNotEmpty
                                  ? _expiry
                                  : 'MM/YY (e.g. 12/28)',
                              subtitleColor: _expiry.isNotEmpty
                                  ? OneUITheme.accentBlue
                                  : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newExpiry = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardExpiryEditorSubpage(
                                      initialExpiry: _expiry,
                                      cardColor: _cardColor,
                                      brand: _brand,
                                      nickname: _nickname,
                                      last4: _last4,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newExpiry != null) {
                                  setState(() => _expiry = newExpiry);
                                }
                              },
                            ),
                            OneUIGroupItem(
                              title: 'Payment method type',
                              subtitle: _type.label,
                              subtitleColor: OneUITheme.accentBlue,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newType = await Navigator.push<PaymentMethodType>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardTypePickerSubpage(
                                      initialType: _type,
                                      cardColor: _cardColor,
                                      brand: _brand,
                                      nickname: _nickname,
                                      last4: _last4,
                                      expiry: _expiry,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newType != null) {
                                  setState(() => _type = newType);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Billing & Preferences
                      OneUISection(
                        title: 'Billing & preferences',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Statement closing day',
                              subtitle: _statementDay != null
                                  ? 'Day $_statementDay of each month'
                                  : 'Optional (1–31)',
                              subtitleColor: _statementDay != null
                                  ? OneUITheme.accentBlue
                                  : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final newDay = await Navigator.push<int?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CardStatementDayPickerSubpage(
                                      initialDay: _statementDay,
                                      cardColor: _cardColor,
                                      brand: _brand,
                                      nickname: _nickname,
                                      last4: _last4,
                                      expiry: _expiry,
                                      isDefault: _isDefault,
                                    ),
                                  ),
                                );
                                if (newDay != null || _statementDay != null) {
                                  setState(() => _statementDay = newDay);
                                }
                              },
                            ),
                            OneUIGroupItem(
                              title: 'Default payment method',
                              subtitle: 'Auto-select when adding new subscriptions',
                              trailing: OneUISwitch(
                                value: _isDefault,
                                onChanged: (val) {
                                  setState(() => _isDefault = val);
                                },
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isDefault = !_isDefault);
                              },
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

          // Progressive OLED Bottom Vignette
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          // Floating Cancel | Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              bottom: bottomInset == 0,
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
}

// ============================================================================
// Realistic Flat Credit Card Mockup Widget (No 3D borders/bevels)
// ============================================================================

class _RealisticFlatCardMockup extends StatelessWidget {
  final Color cardColor;
  final CardBrand brand;
  final String nickname;
  final String last4;
  final String expiry;
  final bool isDefault;

  const _RealisticFlatCardMockup({
    required this.cardColor,
    required this.brand,
    required this.nickname,
    required this.last4,
    required this.expiry,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(cardColor);
    final darkerTone = hsl.withLightness((hsl.lightness * 0.78).clamp(0.0, 1.0)).toColor();

    return AspectRatio(
      aspectRatio: 1.586, // ISO ID-1 credit card aspect ratio (85.6mm x 53.98mm)
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Flat satin matte gradient - no border outlines or 3D extrusions
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor, darkerTone],
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Contactless Wave + Default Pill + Brand Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.contactless_rounded,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                OneUIPaymentBrandIcon(
                  brand: brand,
                  width: 46,
                  height: 30,
                  showShadow: false,
                ),
              ],
            ),

            // Middle: Stylized Brass EMV Chip + Spaced Monospace Card Numbers
            Row(
              children: [
                // Flat EMV Brass Chip
                Container(
                  width: 36,
                  height: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 16,
                          height: 13,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF996515), width: 0.8),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 13,
                        left: 0,
                        right: 0,
                        child: Container(height: 0.8, color: const Color(0xFF996515)),
                      ),
                      Positioned(
                        left: 17.5,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 0.8, color: const Color(0xFF996515)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    last4.isNotEmpty ? '••••  ••••  ••••  $last4' : '••••  ••••  ••••  ••••',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Row: Clean Nickname (NO "cardholder name" label) + Expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    nickname.isNotEmpty ? nickname : 'Card Nickname',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VALID THRU',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiry.isNotEmpty ? expiry : 'MM/YY',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. Dedicated Subpage: Card Color Tint Picker
// ============================================================================

class _CardColorPickerSubpage extends StatefulWidget {
  final Color initialColor;
  final CardBrand brand;
  final String nickname;
  final String last4;
  final String expiry;
  final bool isDefault;

  const _CardColorPickerSubpage({
    required this.initialColor,
    required this.brand,
    required this.nickname,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  @override
  State<_CardColorPickerSubpage> createState() => _CardColorPickerSubpageState();
}

class _CardColorPickerSubpageState extends State<_CardColorPickerSubpage> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Card color tint',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _selectedColor),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: _selectedColor,
                          brand: widget.brand,
                          nickname: widget.nickname,
                          last4: widget.last4,
                          expiry: widget.expiry,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // One UI Swatch Grid with Hex Codes
                      OneUISection(
                        title: 'Select color',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _curatedCardColors.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                            itemBuilder: (context, index) {
                              final color = _curatedCardColors[index];
                              final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                              final hexCode = _colorToHex(color);

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedColor = color);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.2),
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hexCode,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? OneUITheme.accentBlue
                                            : OneUITheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _selectedColor),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. Dedicated Subpage: Card Network / Brand Picker
// ============================================================================

class _CardBrandPickerSubpage extends StatefulWidget {
  final CardBrand initialBrand;
  final Color cardColor;
  final String nickname;
  final String last4;
  final String expiry;
  final bool isDefault;

  const _CardBrandPickerSubpage({
    required this.initialBrand,
    required this.cardColor,
    required this.nickname,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  @override
  State<_CardBrandPickerSubpage> createState() => _CardBrandPickerSubpageState();
}

class _CardBrandPickerSubpageState extends State<_CardBrandPickerSubpage> {
  late CardBrand _selectedBrand;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.initialBrand;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Card network',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _selectedBrand),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: widget.cardColor,
                          brand: _selectedBrand,
                          nickname: widget.nickname,
                          last4: widget.last4,
                          expiry: widget.expiry,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // One UI Group Card with all 12 Supported Brands
                      OneUISection(
                        title: 'Supported networks & wallets',
                        child: OneUIGroupCard(
                          items: CardBrand.values.map((brand) {
                            final isSelected = brand == _selectedBrand;
                            return OneUIGroupItem(
                              leading: OneUIPaymentBrandIcon(
                                brand: brand,
                                width: 38,
                                height: 26,
                              ),
                              title: brand.label,
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: OneUITheme.accentBlue,
                                    )
                                  : null,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedBrand = brand);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _selectedBrand),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. Dedicated Subpage: Card Nickname Editor
// ============================================================================

class _CardNicknameEditorSubpage extends StatefulWidget {
  final String initialNickname;
  final Color cardColor;
  final CardBrand brand;
  final String last4;
  final String expiry;
  final bool isDefault;

  const _CardNicknameEditorSubpage({
    required this.initialNickname,
    required this.cardColor,
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  @override
  State<_CardNicknameEditorSubpage> createState() => _CardNicknameEditorSubpageState();
}

class _CardNicknameEditorSubpageState extends State<_CardNicknameEditorSubpage> {
  late TextEditingController _controller;

  static const List<String> _suggestions = [
    'Personal',
    'Salary',
    'Main Card',
    'Online Shopping',
    'Subscriptions',
    'Travel',
    'Shared / Bills',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Card nickname',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _controller.text.trim()),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: widget.cardColor,
                          brand: widget.brand,
                          nickname: _controller.text,
                          last4: widget.last4,
                          expiry: widget.expiry,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // Text Field Card
                      OneUISection(
                        title: 'Nickname / Alias',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            inputFormatters: [LengthLimitingTextInputFormatter(40)],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'e.g. Salary Card, Personal Debit',
                              hintStyle: const TextStyle(
                                fontSize: 15,
                                color: OneUITheme.textSecondary,
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        size: 20,
                                        color: OneUITheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Suggestions
                      OneUISection(
                        title: 'Quick suggestions',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestions.map((suggestion) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _controller.text = suggestion;
                                setState(() {});
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: OneUITheme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: OneUITheme.cardBorder,
                                ),
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              bottom: bottomInset == 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _controller.text.trim()),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. Dedicated Subpage: Last 4 Digits Editor
// ============================================================================

class _CardLast4EditorSubpage extends StatefulWidget {
  final String initialLast4;
  final Color cardColor;
  final CardBrand brand;
  final String nickname;
  final String expiry;
  final bool isDefault;

  const _CardLast4EditorSubpage({
    required this.initialLast4,
    required this.cardColor,
    required this.brand,
    required this.nickname,
    required this.expiry,
    required this.isDefault,
  });

  @override
  State<_CardLast4EditorSubpage> createState() => _CardLast4EditorSubpageState();
}

class _CardLast4EditorSubpageState extends State<_CardLast4EditorSubpage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLast4);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Last 4 digits',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _controller.text.trim()),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: widget.cardColor,
                          brand: widget.brand,
                          nickname: widget.nickname,
                          last4: _controller.text,
                          expiry: widget.expiry,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // Text Field Card
                      OneUISection(
                        title: 'Card digits (optional)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              color: OneUITheme.accentBlue,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '1234',
                              hintStyle: TextStyle(
                                fontSize: 20,
                                letterSpacing: 4,
                                color: OneUITheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        size: 20,
                                        color: OneUITheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Only the last 4 digits are stored to help you identify which payment card is tied to your recurring subscriptions.',
                          style: TextStyle(
                            fontSize: 13,
                            color: OneUITheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              bottom: bottomInset == 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _controller.text.trim()),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. Dedicated Subpage: Expiry Date Editor
// ============================================================================

class _CardExpiryEditorSubpage extends StatefulWidget {
  final String initialExpiry;
  final Color cardColor;
  final CardBrand brand;
  final String nickname;
  final String last4;
  final bool isDefault;

  const _CardExpiryEditorSubpage({
    required this.initialExpiry,
    required this.cardColor,
    required this.brand,
    required this.nickname,
    required this.last4,
    required this.isDefault,
  });

  @override
  State<_CardExpiryEditorSubpage> createState() => _CardExpiryEditorSubpageState();
}

class _CardExpiryEditorSubpageState extends State<_CardExpiryEditorSubpage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialExpiry);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyYearPreset(int addYears) {
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearStr = ((now.year + addYears) % 100).toString().padLeft(2, '0');
    _controller.text = '$monthStr/$yearStr';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Expiry date',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _controller.text.trim()),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: widget.cardColor,
                          brand: widget.brand,
                          nickname: widget.nickname,
                          last4: widget.last4,
                          expiry: _controller.text,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // Text Field Card
                      OneUISection(
                        title: 'Expiration date (MM/YY)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [LengthLimitingTextInputFormatter(5)],
                            onChanged: (val) {
                              if (val.length == 2 && !_controller.text.contains('/')) {
                                _controller.text = '$val/';
                                _controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _controller.text.length),
                                );
                              }
                              setState(() {});
                            },
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: OneUITheme.accentBlue,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '12/28',
                              hintStyle: TextStyle(
                                fontSize: 18,
                                letterSpacing: 2,
                                color: OneUITheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        size: 20,
                                        color: OneUITheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Presets
                      OneUISection(
                        title: 'Quick preset years',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final years in [1, 2, 3, 5])
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _applyYearPreset(years);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: OneUITheme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: OneUITheme.cardBorder,
                                  ),
                                  child: Text(
                                    '+$years ${years == 1 ? 'Year' : 'Years'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: OneUITheme.textPrimary,
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

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              bottom: bottomInset == 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _controller.text.trim()),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. Dedicated Subpage: Payment Method Type Picker
// ============================================================================

class _CardTypePickerSubpage extends StatefulWidget {
  final PaymentMethodType initialType;
  final Color cardColor;
  final CardBrand brand;
  final String nickname;
  final String last4;
  final String expiry;
  final bool isDefault;

  const _CardTypePickerSubpage({
    required this.initialType,
    required this.cardColor,
    required this.brand,
    required this.nickname,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  @override
  State<_CardTypePickerSubpage> createState() => _CardTypePickerSubpageState();
}

class _CardTypePickerSubpageState extends State<_CardTypePickerSubpage> {
  late PaymentMethodType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Payment method type',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _selectedType),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: widget.cardColor,
                          brand: widget.brand,
                          nickname: widget.nickname,
                          last4: widget.last4,
                          expiry: widget.expiry,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // One UI Group Card with Radio Options
                      OneUISection(
                        title: 'Select type',
                        child: OneUIGroupCard(
                          items: PaymentMethodType.values.map((type) {
                            final isSelected = type == _selectedType;
                            return OneUIGroupItem(
                              leading: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? OneUITheme.accentBlue
                                        : const Color(0xFF5E5E62),
                                    width: isSelected ? 2.0 : 1.6,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isSelected
                                    ? Container(
                                        width: 11,
                                        height: 11,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: OneUITheme.accentBlue,
                                        ),
                                      )
                                    : null,
                              ),
                              title: type.label,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedType = type);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _selectedType),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. Dedicated Subpage: Statement Closing Day Picker
// ============================================================================

class _CardStatementDayPickerSubpage extends StatefulWidget {
  final int? initialDay;
  final Color cardColor;
  final CardBrand brand;
  final String nickname;
  final String last4;
  final String expiry;
  final bool isDefault;

  const _CardStatementDayPickerSubpage({
    required this.initialDay,
    required this.cardColor,
    required this.brand,
    required this.nickname,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  @override
  State<_CardStatementDayPickerSubpage> createState() => _CardStatementDayPickerSubpageState();
}

class _CardStatementDayPickerSubpageState extends State<_CardStatementDayPickerSubpage> {
  late TextEditingController _controller;

  static const List<int> _commonDays = [1, 5, 10, 15, 20, 25, 28];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDay?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _parsedDay {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final val = int.tryParse(text);
    if (val != null && val >= 1 && val <= 31) return val;
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Statement closing day',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context, _parsedDay),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Card Mockup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RealisticFlatCardMockup(
                          cardColor: widget.cardColor,
                          brand: widget.brand,
                          nickname: widget.nickname,
                          last4: widget.last4,
                          expiry: widget.expiry,
                          isDefault: widget.isDefault,
                        ),
                      ),

                      // Text Field Card
                      OneUISection(
                        title: 'Closing day of month (1–31)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: OneUITheme.accentBlue,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '15',
                              hintStyle: TextStyle(
                                fontSize: 20,
                                color: OneUITheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        size: 20,
                                        color: OneUITheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Cycles
                      OneUISection(
                        title: 'Common statement cycles',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final day in _commonDays)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _controller.text = day.toString();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: OneUITheme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: OneUITheme.cardBorder,
                                  ),
                                  child: Text(
                                    'Day $day',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: OneUITheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _controller.clear();
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: OneUITheme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: OneUITheme.cardBorder,
                                ),
                                child: const Text(
                                  'None (Clear)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textSecondary,
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

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              bottom: bottomInset == 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: () => Navigator.pop(context, _parsedDay),
                    saveLabel: 'Apply',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
