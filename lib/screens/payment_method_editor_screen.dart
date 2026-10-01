import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_radio.dart';
import '../widgets/one_ui_switch.dart';
import '../widgets/one_ui_toast.dart';

/// Dedicated Samsung One UI Payment Method Editor Screen.
/// Follows One UI design principles with clean group cards, functional form fields,
/// dedicated subpages, standard One UI squircles (16dp-20dp), and OneUISwitch for toggles.
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
    return context.push<PaymentMethod>(AppRoutes.paymentMethodEditor, extra: method);
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
      cardColorValue: 0xFF2C3440,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Card Details (strictly functional form fields)
                      OneUISection(
                        title: 'Card details',
                        child: OneUIGroupCard(
                          items: [
                            // 1. Card Nickname
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
                                    ),
                                  ),
                                );
                                if (newNickname != null) {
                                  setState(() => _nickname = newNickname);
                                }
                              },
                            ),

                            // 2. Card Network / Provider
                            OneUIGroupItem(
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

                            // 3. Last 4 Digits
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
                                    ),
                                  ),
                                );
                                if (newLast4 != null) {
                                  setState(() => _last4 = newLast4);
                                }
                              },
                            ),

                            // 4. Expiry Date
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
                                    ),
                                  ),
                                );
                                if (newExpiry != null) {
                                  setState(() => _expiry = newExpiry);
                                }
                              },
                            ),

                            // 5. Payment Method Type
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
                                    ),
                                  ),
                                );
                                if (newType != null) {
                                  setState(() => _type = newType);
                                }
                              },
                            ),

                            // 6. Statement Closing Day
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
                                    ),
                                  ),
                                );
                                if (newDay != null || _statementDay != null) {
                                  setState(() => _statementDay = newDay);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Preferences
                      OneUISection(
                        title: 'Preferences',
                        child: OneUIGroupCard(
                          items: [
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
// 1. Dedicated Subpage: Card Network / Brand Picker
// ============================================================================

class _CardBrandPickerSubpage extends StatefulWidget {
  final CardBrand initialBrand;

  const _CardBrandPickerSubpage({
    required this.initialBrand,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One UI Group Card with all supported brands and right-aligned radio buttons
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
                              trailing: OneUIRadio(isSelected: isSelected),
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
// 2. Dedicated Subpage: Card Nickname Editor
// ============================================================================

class _CardNicknameEditorSubpage extends StatefulWidget {
  final String initialNickname;

  const _CardNicknameEditorSubpage({
    required this.initialNickname,
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
                    8,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Field Card (Standard One UI 18dp squircle)
                      OneUISection(
                        title: 'Nickname / Alias',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.fieldBorderRadius,
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

                      // Quick Suggestions (Standard One UI 18dp squircles)
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: OneUITheme.cardColor,
                                  borderRadius: BorderRadius.circular(18),
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
// 3. Dedicated Subpage: Last 4 Digits Editor
// ============================================================================

class _CardLast4EditorSubpage extends StatefulWidget {
  final String initialLast4;

  const _CardLast4EditorSubpage({
    required this.initialLast4,
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
                    8,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Field Card (Standard One UI 18dp squircle)
                      OneUISection(
                        title: 'Card digits (optional)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.fieldBorderRadius,
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
// 4. Dedicated Subpage: Expiry Date Editor
// ============================================================================

class _CardExpiryEditorSubpage extends StatefulWidget {
  final String initialExpiry;

  const _CardExpiryEditorSubpage({
    required this.initialExpiry,
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
                    8,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Field Card (Standard One UI 18dp squircle)
                      OneUISection(
                        title: 'Expiration date (MM/YY)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.fieldBorderRadius,
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

                      // Quick Presets (Standard One UI 18dp squircles)
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
                                    borderRadius: BorderRadius.circular(18),
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
// 5. Dedicated Subpage: Payment Method Type Picker
// ============================================================================

class _CardTypePickerSubpage extends StatefulWidget {
  final PaymentMethodType initialType;

  const _CardTypePickerSubpage({
    required this.initialType,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One UI Group Card with Radio Options (No chevron icon)
                      OneUISection(
                        title: 'Select type',
                        child: OneUIGroupCard(
                          items: PaymentMethodType.values.map((type) {
                            final isSelected = type == _selectedType;
                            return OneUIGroupItem(
                              leading: OneUIRadio(isSelected: isSelected),
                              title: type.label,
                              trailing: const SizedBox.shrink(),
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
// 6. Dedicated Subpage: Statement Closing Day Picker
// ============================================================================

class _CardStatementDayPickerSubpage extends StatefulWidget {
  final int? initialDay;

  const _CardStatementDayPickerSubpage({
    required this.initialDay,
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
                    8,
                    16,
                    bottomInset > 0 ? (bottomInset + 90) : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Field Card (Standard One UI 18dp squircle)
                      OneUISection(
                        title: 'Closing day of month (1–31)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.fieldBorderRadius,
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

                      // Common Day Presets (Standard One UI 18dp squircles)
                      OneUISection(
                        title: 'Common statement days',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _commonDays.map((day) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _controller.text = day.toString();
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: OneUITheme.cardColor,
                                  borderRadius: BorderRadius.circular(18),
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
