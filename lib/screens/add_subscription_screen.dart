import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  BillingCycle _selectedCycle = BillingCycle.monthly;
  SubscriptionCategory _selectedCategory = SubscriptionCategory.entertainment;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  Color _selectedColor = const Color(0xFF2D6CE5);
  IconData _selectedIcon = Icons.subscriptions_rounded;
  int _reminderDays = 2;

  Subscription? _selectedPopular;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _selectPopular(Subscription sub) {
    setState(() {
      _selectedPopular = sub;
      _nameController.text = sub.name;
      _priceController.text = sub.price.toStringAsFixed(2);
      _descController.text = sub.description;
      _selectedCycle = sub.billingCycle;
      _selectedCategory = sub.category;
      _selectedColor = sub.brandColor;
      _selectedIcon = sub.iconData;
      _reminderDays = sub.reminderDays;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: OneUITheme.accentBlue,
              surface: OneUITheme.surfaceCard,
              onSurface: OneUITheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSubscription() {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();

    if (name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a service name and price'),
          backgroundColor: OneUITheme.surfacePill,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final newSub = Subscription(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: _descController.text.trim().isEmpty
          ? '${_selectedCategory.label} subscription'
          : _descController.text.trim(),
      price: price,
      billingCycle: _selectedCycle,
      category: _selectedCategory,
      brandColor: _selectedColor,
      iconData: _selectedIcon,
      nextBillingDate: _selectedDate,
      reminderDays: _reminderDays,
      status: SubscriptionStatus.active,
    );

    SubscriptionStore.instance.addSubscription(newSub);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added successfully!'),
        backgroundColor: OneUITheme.surfacePill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // One UI Signature Collapsible Header with Back Button (Screenshots 1-4)
          SliverPersistentHeader(
            pinned: true,
            delegate: OneUICollapsibleHeaderDelegate(
              title: 'Add Subscription',
              hasBigHeader: false,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                GestureDetector(
                  onTap: _saveSubscription,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: OneUITheme.accentGreen,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Popular Subscriptions Carousel
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'Top & Popular Subscriptions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 106,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: popularCatalog.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final pop = popularCatalog[index];
                        final isSelected = _selectedPopular?.id == pop.id;

                        return GestureDetector(
                          onTap: () => _selectPopular(pop),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 96,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? OneUITheme.surfacePillActive
                                  : OneUITheme.surfaceCard,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected
                                    ? pop.brandColor
                                    : OneUITheme.surfacePillBorder,
                                width: isSelected ? 1.5 : 0.8,
                              ),
                              boxShadow: OneUITheme.cardShadow,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: pop.brandColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(pop.iconData, color: Colors.white, size: 20),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '\$${pop.price.toStringAsFixed(0)}/mo',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Subscription Details Form
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                  ),

                  // Card 1: Service Name & Description
                  Container(
                    decoration: BoxDecoration(
                      color: OneUITheme.cardColor,
                      borderRadius: OneUITheme.cardBorderRadius,
                      border: OneUITheme.cardBorder,
                      boxShadow: OneUITheme.cardShadow,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: OneUITheme.textPrimary, fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'Service Name',
                            labelStyle: TextStyle(color: OneUITheme.textSecondary),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.label_outline_rounded, color: OneUITheme.textSecondary),
                          ),
                        ),
                        const Divider(height: 1),
                        TextField(
                          controller: _descController,
                          style: const TextStyle(color: OneUITheme.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Plan or Description (optional)',
                            labelStyle: TextStyle(color: OneUITheme.textSecondary),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.info_outline_rounded, color: OneUITheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Card 2: Price & Billing Frequency
                  Container(
                    decoration: BoxDecoration(
                      color: OneUITheme.cardColor,
                      borderRadius: OneUITheme.cardBorderRadius,
                      border: OneUITheme.cardBorder,
                      boxShadow: OneUITheme.cardShadow,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            color: OneUITheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            prefixText: '\$ ',
                            prefixStyle: TextStyle(color: OneUITheme.textPrimary, fontSize: 22),
                            labelText: 'Price',
                            labelStyle: TextStyle(color: OneUITheme.textSecondary),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Billing Cycle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: OneUITheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: BillingCycle.values.map((cycle) {
                            final isSelected = _selectedCycle == cycle;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCycle = cycle),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? OneUITheme.accentBlue
                                      : OneUITheme.floatingColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cycle.label,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    letterSpacing: -0.2,
                                    color: isSelected ? Colors.white : OneUITheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Card 3: Next Renewal & Reminders
                  OneUICard(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: OneUITheme.accentBlue, size: 20),
                    ),
                    title: 'Next Renewal Date',
                    subtitle: dateFormat.format(_selectedDate),
                    subtitleColor: OneUITheme.accentBlue,
                    trailing: const Icon(Icons.chevron_right_rounded, color: OneUITheme.textSecondary),
                    onTap: _pickDate,
                  ),

                  const SizedBox(height: 14),

                  // Card 4: Reminder Setting
                  OneUICard(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: OneUITheme.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: OneUITheme.accentAmber, size: 20),
                    ),
                    title: 'Renewal Notification',
                    subtitle: 'Alert $_reminderDays days before renewal',
                    trailing: DropdownButton<int>(
                      value: _reminderDays,
                      dropdownColor: OneUITheme.surfacePill,
                      underline: const SizedBox(),
                      style: const TextStyle(color: OneUITheme.textPrimary, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 day')),
                        DropdownMenuItem(value: 2, child: Text('2 days')),
                        DropdownMenuItem(value: 3, child: Text('3 days')),
                        DropdownMenuItem(value: 7, child: Text('1 week')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _reminderDays = val);
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Bottom Flat Save Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: OneUITheme.accentGreen,
                      borderRadius: OneUITheme.pillBorderRadius,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: OneUITheme.pillBorderRadius,
                      child: InkWell(
                        onTap: _saveSubscription,
                        borderRadius: OneUITheme.pillBorderRadius,
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: const Center(
                          child: Text(
                            'Save Subscription',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
