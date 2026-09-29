// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubscriptionsTableTable extends SubscriptionsTable
    with TableInfo<$SubscriptionsTableTable, SubscriptionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('\$'),
  );
  static const VerificationMeta _billingCycleMeta = const VerificationMeta(
    'billingCycle',
  );
  @override
  late final GeneratedColumn<String> billingCycle = GeneratedColumn<String>(
    'billing_cycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandColorValueMeta = const VerificationMeta(
    'brandColorValue',
  );
  @override
  late final GeneratedColumn<int> brandColorValue = GeneratedColumn<int>(
    'brand_color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconFontFamilyMeta = const VerificationMeta(
    'iconFontFamily',
  );
  @override
  late final GeneratedColumn<String> iconFontFamily = GeneratedColumn<String>(
    'icon_font_family',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextBillingDateMeta = const VerificationMeta(
    'nextBillingDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextBillingDate =
      GeneratedColumn<DateTime>(
        'next_billing_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodIdMeta = const VerificationMeta(
    'paymentMethodId',
  );
  @override
  late final GeneratedColumn<String> paymentMethodId = GeneratedColumn<String>(
    'payment_method_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderDaysMeta = const VerificationMeta(
    'reminderDays',
  );
  @override
  late final GeneratedColumn<int> reminderDays = GeneratedColumn<int>(
    'reminder_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _isPopularMeta = const VerificationMeta(
    'isPopular',
  );
  @override
  late final GeneratedColumn<bool> isPopular = GeneratedColumn<bool>(
    'is_popular',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_popular" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<DateTime>, String>
  paymentHistory =
      GeneratedColumn<String>(
        'payment_history',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<DateTime>>(
        $SubscriptionsTableTable.$converterpaymentHistory,
      );
  static const VerificationMeta _accountUrlMeta = const VerificationMeta(
    'accountUrl',
  );
  @override
  late final GeneratedColumn<String> accountUrl = GeneratedColumn<String>(
    'account_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandPresetIdMeta = const VerificationMeta(
    'brandPresetId',
  );
  @override
  late final GeneratedColumn<String> brandPresetId = GeneratedColumn<String>(
    'brand_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoRenewMeta = const VerificationMeta(
    'autoRenew',
  );
  @override
  late final GeneratedColumn<bool> autoRenew = GeneratedColumn<bool>(
    'auto_renew',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_renew" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _anchorDayMeta = const VerificationMeta(
    'anchorDay',
  );
  @override
  late final GeneratedColumn<int> anchorDay = GeneratedColumn<int>(
    'anchor_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeMinutesMeta =
      const VerificationMeta('reminderTimeMinutes');
  @override
  late final GeneratedColumn<int> reminderTimeMinutes = GeneratedColumn<int>(
    'reminder_time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    price,
    currency,
    billingCycle,
    category,
    brandColorValue,
    iconCodePoint,
    iconFontFamily,
    nextBillingDate,
    status,
    paymentMethod,
    paymentMethodId,
    reminderDays,
    isPopular,
    notes,
    paymentHistory,
    accountUrl,
    logoUrl,
    brandPresetId,
    autoRenew,
    anchorDay,
    reminderTimeMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('billing_cycle')) {
      context.handle(
        _billingCycleMeta,
        billingCycle.isAcceptableOrUnknown(
          data['billing_cycle']!,
          _billingCycleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billingCycleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('brand_color_value')) {
      context.handle(
        _brandColorValueMeta,
        brandColorValue.isAcceptableOrUnknown(
          data['brand_color_value']!,
          _brandColorValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_brandColorValueMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    }
    if (data.containsKey('icon_font_family')) {
      context.handle(
        _iconFontFamilyMeta,
        iconFontFamily.isAcceptableOrUnknown(
          data['icon_font_family']!,
          _iconFontFamilyMeta,
        ),
      );
    }
    if (data.containsKey('next_billing_date')) {
      context.handle(
        _nextBillingDateMeta,
        nextBillingDate.isAcceptableOrUnknown(
          data['next_billing_date']!,
          _nextBillingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextBillingDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
        _paymentMethodIdMeta,
        paymentMethodId.isAcceptableOrUnknown(
          data['payment_method_id']!,
          _paymentMethodIdMeta,
        ),
      );
    }
    if (data.containsKey('reminder_days')) {
      context.handle(
        _reminderDaysMeta,
        reminderDays.isAcceptableOrUnknown(
          data['reminder_days']!,
          _reminderDaysMeta,
        ),
      );
    }
    if (data.containsKey('is_popular')) {
      context.handle(
        _isPopularMeta,
        isPopular.isAcceptableOrUnknown(data['is_popular']!, _isPopularMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('account_url')) {
      context.handle(
        _accountUrlMeta,
        accountUrl.isAcceptableOrUnknown(data['account_url']!, _accountUrlMeta),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('brand_preset_id')) {
      context.handle(
        _brandPresetIdMeta,
        brandPresetId.isAcceptableOrUnknown(
          data['brand_preset_id']!,
          _brandPresetIdMeta,
        ),
      );
    }
    if (data.containsKey('auto_renew')) {
      context.handle(
        _autoRenewMeta,
        autoRenew.isAcceptableOrUnknown(data['auto_renew']!, _autoRenewMeta),
      );
    }
    if (data.containsKey('anchor_day')) {
      context.handle(
        _anchorDayMeta,
        anchorDay.isAcceptableOrUnknown(data['anchor_day']!, _anchorDayMeta),
      );
    }
    if (data.containsKey('reminder_time_minutes')) {
      context.handle(
        _reminderTimeMinutesMeta,
        reminderTimeMinutes.isAcceptableOrUnknown(
          data['reminder_time_minutes']!,
          _reminderTimeMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      billingCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_cycle'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      brandColorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brand_color_value'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      ),
      iconFontFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_font_family'],
      ),
      nextBillingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_billing_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      paymentMethodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_id'],
      ),
      reminderDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_days'],
      )!,
      isPopular: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_popular'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      paymentHistory: $SubscriptionsTableTable.$converterpaymentHistory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_history'],
        )!,
      ),
      accountUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_url'],
      )!,
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      brandPresetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_preset_id'],
      ),
      autoRenew: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_renew'],
      )!,
      anchorDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_day'],
      ),
      reminderTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_time_minutes'],
      ),
    );
  }

  @override
  $SubscriptionsTableTable createAlias(String alias) {
    return $SubscriptionsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<DateTime>, String> $converterpaymentHistory =
      const DateTimeListConverter();
}

class SubscriptionEntry extends DataClass
    implements Insertable<SubscriptionEntry> {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingCycle;
  final String category;
  final int brandColorValue;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final DateTime nextBillingDate;
  final String status;
  final String paymentMethod;
  final String? paymentMethodId;
  final int reminderDays;
  final bool isPopular;
  final String notes;
  final List<DateTime> paymentHistory;
  final String accountUrl;
  final String? logoUrl;
  final String? brandPresetId;
  final bool autoRenew;
  final int? anchorDay;

  /// Added in schema v2: reminder time of day in minutes after midnight (null = global default).
  final int? reminderTimeMinutes;
  const SubscriptionEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.category,
    required this.brandColorValue,
    this.iconCodePoint,
    this.iconFontFamily,
    required this.nextBillingDate,
    required this.status,
    required this.paymentMethod,
    this.paymentMethodId,
    required this.reminderDays,
    required this.isPopular,
    required this.notes,
    required this.paymentHistory,
    required this.accountUrl,
    this.logoUrl,
    this.brandPresetId,
    required this.autoRenew,
    this.anchorDay,
    this.reminderTimeMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['price'] = Variable<double>(price);
    map['currency'] = Variable<String>(currency);
    map['billing_cycle'] = Variable<String>(billingCycle);
    map['category'] = Variable<String>(category);
    map['brand_color_value'] = Variable<int>(brandColorValue);
    if (!nullToAbsent || iconCodePoint != null) {
      map['icon_code_point'] = Variable<int>(iconCodePoint);
    }
    if (!nullToAbsent || iconFontFamily != null) {
      map['icon_font_family'] = Variable<String>(iconFontFamily);
    }
    map['next_billing_date'] = Variable<DateTime>(nextBillingDate);
    map['status'] = Variable<String>(status);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || paymentMethodId != null) {
      map['payment_method_id'] = Variable<String>(paymentMethodId);
    }
    map['reminder_days'] = Variable<int>(reminderDays);
    map['is_popular'] = Variable<bool>(isPopular);
    map['notes'] = Variable<String>(notes);
    {
      map['payment_history'] = Variable<String>(
        $SubscriptionsTableTable.$converterpaymentHistory.toSql(paymentHistory),
      );
    }
    map['account_url'] = Variable<String>(accountUrl);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || brandPresetId != null) {
      map['brand_preset_id'] = Variable<String>(brandPresetId);
    }
    map['auto_renew'] = Variable<bool>(autoRenew);
    if (!nullToAbsent || anchorDay != null) {
      map['anchor_day'] = Variable<int>(anchorDay);
    }
    if (!nullToAbsent || reminderTimeMinutes != null) {
      map['reminder_time_minutes'] = Variable<int>(reminderTimeMinutes);
    }
    return map;
  }

  SubscriptionsTableCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      price: Value(price),
      currency: Value(currency),
      billingCycle: Value(billingCycle),
      category: Value(category),
      brandColorValue: Value(brandColorValue),
      iconCodePoint: iconCodePoint == null && nullToAbsent
          ? const Value.absent()
          : Value(iconCodePoint),
      iconFontFamily: iconFontFamily == null && nullToAbsent
          ? const Value.absent()
          : Value(iconFontFamily),
      nextBillingDate: Value(nextBillingDate),
      status: Value(status),
      paymentMethod: Value(paymentMethod),
      paymentMethodId: paymentMethodId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodId),
      reminderDays: Value(reminderDays),
      isPopular: Value(isPopular),
      notes: Value(notes),
      paymentHistory: Value(paymentHistory),
      accountUrl: Value(accountUrl),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      brandPresetId: brandPresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(brandPresetId),
      autoRenew: Value(autoRenew),
      anchorDay: anchorDay == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorDay),
      reminderTimeMinutes: reminderTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTimeMinutes),
    );
  }

  factory SubscriptionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      currency: serializer.fromJson<String>(json['currency']),
      billingCycle: serializer.fromJson<String>(json['billingCycle']),
      category: serializer.fromJson<String>(json['category']),
      brandColorValue: serializer.fromJson<int>(json['brandColorValue']),
      iconCodePoint: serializer.fromJson<int?>(json['iconCodePoint']),
      iconFontFamily: serializer.fromJson<String?>(json['iconFontFamily']),
      nextBillingDate: serializer.fromJson<DateTime>(json['nextBillingDate']),
      status: serializer.fromJson<String>(json['status']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentMethodId: serializer.fromJson<String?>(json['paymentMethodId']),
      reminderDays: serializer.fromJson<int>(json['reminderDays']),
      isPopular: serializer.fromJson<bool>(json['isPopular']),
      notes: serializer.fromJson<String>(json['notes']),
      paymentHistory: serializer.fromJson<List<DateTime>>(
        json['paymentHistory'],
      ),
      accountUrl: serializer.fromJson<String>(json['accountUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      brandPresetId: serializer.fromJson<String?>(json['brandPresetId']),
      autoRenew: serializer.fromJson<bool>(json['autoRenew']),
      anchorDay: serializer.fromJson<int?>(json['anchorDay']),
      reminderTimeMinutes: serializer.fromJson<int?>(
        json['reminderTimeMinutes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'price': serializer.toJson<double>(price),
      'currency': serializer.toJson<String>(currency),
      'billingCycle': serializer.toJson<String>(billingCycle),
      'category': serializer.toJson<String>(category),
      'brandColorValue': serializer.toJson<int>(brandColorValue),
      'iconCodePoint': serializer.toJson<int?>(iconCodePoint),
      'iconFontFamily': serializer.toJson<String?>(iconFontFamily),
      'nextBillingDate': serializer.toJson<DateTime>(nextBillingDate),
      'status': serializer.toJson<String>(status),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentMethodId': serializer.toJson<String?>(paymentMethodId),
      'reminderDays': serializer.toJson<int>(reminderDays),
      'isPopular': serializer.toJson<bool>(isPopular),
      'notes': serializer.toJson<String>(notes),
      'paymentHistory': serializer.toJson<List<DateTime>>(paymentHistory),
      'accountUrl': serializer.toJson<String>(accountUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'brandPresetId': serializer.toJson<String?>(brandPresetId),
      'autoRenew': serializer.toJson<bool>(autoRenew),
      'anchorDay': serializer.toJson<int?>(anchorDay),
      'reminderTimeMinutes': serializer.toJson<int?>(reminderTimeMinutes),
    };
  }

  SubscriptionEntry copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? billingCycle,
    String? category,
    int? brandColorValue,
    Value<int?> iconCodePoint = const Value.absent(),
    Value<String?> iconFontFamily = const Value.absent(),
    DateTime? nextBillingDate,
    String? status,
    String? paymentMethod,
    Value<String?> paymentMethodId = const Value.absent(),
    int? reminderDays,
    bool? isPopular,
    String? notes,
    List<DateTime>? paymentHistory,
    String? accountUrl,
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> brandPresetId = const Value.absent(),
    bool? autoRenew,
    Value<int?> anchorDay = const Value.absent(),
    Value<int?> reminderTimeMinutes = const Value.absent(),
  }) => SubscriptionEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    billingCycle: billingCycle ?? this.billingCycle,
    category: category ?? this.category,
    brandColorValue: brandColorValue ?? this.brandColorValue,
    iconCodePoint: iconCodePoint.present
        ? iconCodePoint.value
        : this.iconCodePoint,
    iconFontFamily: iconFontFamily.present
        ? iconFontFamily.value
        : this.iconFontFamily,
    nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    status: status ?? this.status,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentMethodId: paymentMethodId.present
        ? paymentMethodId.value
        : this.paymentMethodId,
    reminderDays: reminderDays ?? this.reminderDays,
    isPopular: isPopular ?? this.isPopular,
    notes: notes ?? this.notes,
    paymentHistory: paymentHistory ?? this.paymentHistory,
    accountUrl: accountUrl ?? this.accountUrl,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    brandPresetId: brandPresetId.present
        ? brandPresetId.value
        : this.brandPresetId,
    autoRenew: autoRenew ?? this.autoRenew,
    anchorDay: anchorDay.present ? anchorDay.value : this.anchorDay,
    reminderTimeMinutes: reminderTimeMinutes.present
        ? reminderTimeMinutes.value
        : this.reminderTimeMinutes,
  );
  SubscriptionEntry copyWithCompanion(SubscriptionsTableCompanion data) {
    return SubscriptionEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      billingCycle: data.billingCycle.present
          ? data.billingCycle.value
          : this.billingCycle,
      category: data.category.present ? data.category.value : this.category,
      brandColorValue: data.brandColorValue.present
          ? data.brandColorValue.value
          : this.brandColorValue,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      iconFontFamily: data.iconFontFamily.present
          ? data.iconFontFamily.value
          : this.iconFontFamily,
      nextBillingDate: data.nextBillingDate.present
          ? data.nextBillingDate.value
          : this.nextBillingDate,
      status: data.status.present ? data.status.value : this.status,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      reminderDays: data.reminderDays.present
          ? data.reminderDays.value
          : this.reminderDays,
      isPopular: data.isPopular.present ? data.isPopular.value : this.isPopular,
      notes: data.notes.present ? data.notes.value : this.notes,
      paymentHistory: data.paymentHistory.present
          ? data.paymentHistory.value
          : this.paymentHistory,
      accountUrl: data.accountUrl.present
          ? data.accountUrl.value
          : this.accountUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      brandPresetId: data.brandPresetId.present
          ? data.brandPresetId.value
          : this.brandPresetId,
      autoRenew: data.autoRenew.present ? data.autoRenew.value : this.autoRenew,
      anchorDay: data.anchorDay.present ? data.anchorDay.value : this.anchorDay,
      reminderTimeMinutes: data.reminderTimeMinutes.present
          ? data.reminderTimeMinutes.value
          : this.reminderTimeMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('category: $category, ')
          ..write('brandColorValue: $brandColorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('iconFontFamily: $iconFontFamily, ')
          ..write('nextBillingDate: $nextBillingDate, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('reminderDays: $reminderDays, ')
          ..write('isPopular: $isPopular, ')
          ..write('notes: $notes, ')
          ..write('paymentHistory: $paymentHistory, ')
          ..write('accountUrl: $accountUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('brandPresetId: $brandPresetId, ')
          ..write('autoRenew: $autoRenew, ')
          ..write('anchorDay: $anchorDay, ')
          ..write('reminderTimeMinutes: $reminderTimeMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    description,
    price,
    currency,
    billingCycle,
    category,
    brandColorValue,
    iconCodePoint,
    iconFontFamily,
    nextBillingDate,
    status,
    paymentMethod,
    paymentMethodId,
    reminderDays,
    isPopular,
    notes,
    paymentHistory,
    accountUrl,
    logoUrl,
    brandPresetId,
    autoRenew,
    anchorDay,
    reminderTimeMinutes,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.billingCycle == this.billingCycle &&
          other.category == this.category &&
          other.brandColorValue == this.brandColorValue &&
          other.iconCodePoint == this.iconCodePoint &&
          other.iconFontFamily == this.iconFontFamily &&
          other.nextBillingDate == this.nextBillingDate &&
          other.status == this.status &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentMethodId == this.paymentMethodId &&
          other.reminderDays == this.reminderDays &&
          other.isPopular == this.isPopular &&
          other.notes == this.notes &&
          other.paymentHistory == this.paymentHistory &&
          other.accountUrl == this.accountUrl &&
          other.logoUrl == this.logoUrl &&
          other.brandPresetId == this.brandPresetId &&
          other.autoRenew == this.autoRenew &&
          other.anchorDay == this.anchorDay &&
          other.reminderTimeMinutes == this.reminderTimeMinutes);
}

class SubscriptionsTableCompanion extends UpdateCompanion<SubscriptionEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<double> price;
  final Value<String> currency;
  final Value<String> billingCycle;
  final Value<String> category;
  final Value<int> brandColorValue;
  final Value<int?> iconCodePoint;
  final Value<String?> iconFontFamily;
  final Value<DateTime> nextBillingDate;
  final Value<String> status;
  final Value<String> paymentMethod;
  final Value<String?> paymentMethodId;
  final Value<int> reminderDays;
  final Value<bool> isPopular;
  final Value<String> notes;
  final Value<List<DateTime>> paymentHistory;
  final Value<String> accountUrl;
  final Value<String?> logoUrl;
  final Value<String?> brandPresetId;
  final Value<bool> autoRenew;
  final Value<int?> anchorDay;
  final Value<int?> reminderTimeMinutes;
  final Value<int> rowid;
  const SubscriptionsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.billingCycle = const Value.absent(),
    this.category = const Value.absent(),
    this.brandColorValue = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.iconFontFamily = const Value.absent(),
    this.nextBillingDate = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.reminderDays = const Value.absent(),
    this.isPopular = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentHistory = const Value.absent(),
    this.accountUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.brandPresetId = const Value.absent(),
    this.autoRenew = const Value.absent(),
    this.anchorDay = const Value.absent(),
    this.reminderTimeMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsTableCompanion.insert({
    required String id,
    required String name,
    required String description,
    required double price,
    this.currency = const Value.absent(),
    required String billingCycle,
    required String category,
    required int brandColorValue,
    this.iconCodePoint = const Value.absent(),
    this.iconFontFamily = const Value.absent(),
    required DateTime nextBillingDate,
    required String status,
    required String paymentMethod,
    this.paymentMethodId = const Value.absent(),
    this.reminderDays = const Value.absent(),
    this.isPopular = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentHistory = const Value.absent(),
    this.accountUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.brandPresetId = const Value.absent(),
    this.autoRenew = const Value.absent(),
    this.anchorDay = const Value.absent(),
    this.reminderTimeMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       price = Value(price),
       billingCycle = Value(billingCycle),
       category = Value(category),
       brandColorValue = Value(brandColorValue),
       nextBillingDate = Value(nextBillingDate),
       status = Value(status),
       paymentMethod = Value(paymentMethod);
  static Insertable<SubscriptionEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<String>? currency,
    Expression<String>? billingCycle,
    Expression<String>? category,
    Expression<int>? brandColorValue,
    Expression<int>? iconCodePoint,
    Expression<String>? iconFontFamily,
    Expression<DateTime>? nextBillingDate,
    Expression<String>? status,
    Expression<String>? paymentMethod,
    Expression<String>? paymentMethodId,
    Expression<int>? reminderDays,
    Expression<bool>? isPopular,
    Expression<String>? notes,
    Expression<String>? paymentHistory,
    Expression<String>? accountUrl,
    Expression<String>? logoUrl,
    Expression<String>? brandPresetId,
    Expression<bool>? autoRenew,
    Expression<int>? anchorDay,
    Expression<int>? reminderTimeMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      if (category != null) 'category': category,
      if (brandColorValue != null) 'brand_color_value': brandColorValue,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (iconFontFamily != null) 'icon_font_family': iconFontFamily,
      if (nextBillingDate != null) 'next_billing_date': nextBillingDate,
      if (status != null) 'status': status,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (reminderDays != null) 'reminder_days': reminderDays,
      if (isPopular != null) 'is_popular': isPopular,
      if (notes != null) 'notes': notes,
      if (paymentHistory != null) 'payment_history': paymentHistory,
      if (accountUrl != null) 'account_url': accountUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (brandPresetId != null) 'brand_preset_id': brandPresetId,
      if (autoRenew != null) 'auto_renew': autoRenew,
      if (anchorDay != null) 'anchor_day': anchorDay,
      if (reminderTimeMinutes != null)
        'reminder_time_minutes': reminderTimeMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<double>? price,
    Value<String>? currency,
    Value<String>? billingCycle,
    Value<String>? category,
    Value<int>? brandColorValue,
    Value<int?>? iconCodePoint,
    Value<String?>? iconFontFamily,
    Value<DateTime>? nextBillingDate,
    Value<String>? status,
    Value<String>? paymentMethod,
    Value<String?>? paymentMethodId,
    Value<int>? reminderDays,
    Value<bool>? isPopular,
    Value<String>? notes,
    Value<List<DateTime>>? paymentHistory,
    Value<String>? accountUrl,
    Value<String?>? logoUrl,
    Value<String?>? brandPresetId,
    Value<bool>? autoRenew,
    Value<int?>? anchorDay,
    Value<int?>? reminderTimeMinutes,
    Value<int>? rowid,
  }) {
    return SubscriptionsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      brandColorValue: brandColorValue ?? this.brandColorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      reminderDays: reminderDays ?? this.reminderDays,
      isPopular: isPopular ?? this.isPopular,
      notes: notes ?? this.notes,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      accountUrl: accountUrl ?? this.accountUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      brandPresetId: brandPresetId ?? this.brandPresetId,
      autoRenew: autoRenew ?? this.autoRenew,
      anchorDay: anchorDay ?? this.anchorDay,
      reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (billingCycle.present) {
      map['billing_cycle'] = Variable<String>(billingCycle.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brandColorValue.present) {
      map['brand_color_value'] = Variable<int>(brandColorValue.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (iconFontFamily.present) {
      map['icon_font_family'] = Variable<String>(iconFontFamily.value);
    }
    if (nextBillingDate.present) {
      map['next_billing_date'] = Variable<DateTime>(nextBillingDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<String>(paymentMethodId.value);
    }
    if (reminderDays.present) {
      map['reminder_days'] = Variable<int>(reminderDays.value);
    }
    if (isPopular.present) {
      map['is_popular'] = Variable<bool>(isPopular.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paymentHistory.present) {
      map['payment_history'] = Variable<String>(
        $SubscriptionsTableTable.$converterpaymentHistory.toSql(
          paymentHistory.value,
        ),
      );
    }
    if (accountUrl.present) {
      map['account_url'] = Variable<String>(accountUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (brandPresetId.present) {
      map['brand_preset_id'] = Variable<String>(brandPresetId.value);
    }
    if (autoRenew.present) {
      map['auto_renew'] = Variable<bool>(autoRenew.value);
    }
    if (anchorDay.present) {
      map['anchor_day'] = Variable<int>(anchorDay.value);
    }
    if (reminderTimeMinutes.present) {
      map['reminder_time_minutes'] = Variable<int>(reminderTimeMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('category: $category, ')
          ..write('brandColorValue: $brandColorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('iconFontFamily: $iconFontFamily, ')
          ..write('nextBillingDate: $nextBillingDate, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('reminderDays: $reminderDays, ')
          ..write('isPopular: $isPopular, ')
          ..write('notes: $notes, ')
          ..write('paymentHistory: $paymentHistory, ')
          ..write('accountUrl: $accountUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('brandPresetId: $brandPresetId, ')
          ..write('autoRenew: $autoRenew, ')
          ..write('anchorDay: $anchorDay, ')
          ..write('reminderTimeMinutes: $reminderTimeMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTableTable extends PaymentMethodsTable
    with TableInfo<$PaymentMethodsTableTable, PaymentMethodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<String> expiryDate = GeneratedColumn<String>(
    'expiry_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cardColorValueMeta = const VerificationMeta(
    'cardColorValue',
  );
  @override
  late final GeneratedColumn<int> cardColorValue = GeneratedColumn<int>(
    'card_color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF2C3440),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statementDayMeta = const VerificationMeta(
    'statementDay',
  );
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
    'statement_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nickname,
    type,
    brand,
    last4,
    expiryDate,
    cardColorValue,
    isDefault,
    statementDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('card_color_value')) {
      context.handle(
        _cardColorValueMeta,
        cardColorValue.isAcceptableOrUnknown(
          data['card_color_value']!,
          _cardColorValueMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('statement_day')) {
      context.handle(
        _statementDayMeta,
        statementDay.isAcceptableOrUnknown(
          data['statement_day']!,
          _statementDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      )!,
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expiry_date'],
      )!,
      cardColorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_color_value'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      statementDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_day'],
      ),
    );
  }

  @override
  $PaymentMethodsTableTable createAlias(String alias) {
    return $PaymentMethodsTableTable(attachedDatabase, alias);
  }
}

class PaymentMethodEntry extends DataClass
    implements Insertable<PaymentMethodEntry> {
  final String id;
  final String nickname;
  final String type;
  final String brand;
  final String last4;
  final String expiryDate;
  final int cardColorValue;
  final bool isDefault;
  final int? statementDay;
  const PaymentMethodEntry({
    required this.id,
    required this.nickname,
    required this.type,
    required this.brand,
    required this.last4,
    required this.expiryDate,
    required this.cardColorValue,
    required this.isDefault,
    this.statementDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nickname'] = Variable<String>(nickname);
    map['type'] = Variable<String>(type);
    map['brand'] = Variable<String>(brand);
    map['last4'] = Variable<String>(last4);
    map['expiry_date'] = Variable<String>(expiryDate);
    map['card_color_value'] = Variable<int>(cardColorValue);
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    return map;
  }

  PaymentMethodsTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsTableCompanion(
      id: Value(id),
      nickname: Value(nickname),
      type: Value(type),
      brand: Value(brand),
      last4: Value(last4),
      expiryDate: Value(expiryDate),
      cardColorValue: Value(cardColorValue),
      isDefault: Value(isDefault),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
    );
  }

  factory PaymentMethodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodEntry(
      id: serializer.fromJson<String>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      type: serializer.fromJson<String>(json['type']),
      brand: serializer.fromJson<String>(json['brand']),
      last4: serializer.fromJson<String>(json['last4']),
      expiryDate: serializer.fromJson<String>(json['expiryDate']),
      cardColorValue: serializer.fromJson<int>(json['cardColorValue']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nickname': serializer.toJson<String>(nickname),
      'type': serializer.toJson<String>(type),
      'brand': serializer.toJson<String>(brand),
      'last4': serializer.toJson<String>(last4),
      'expiryDate': serializer.toJson<String>(expiryDate),
      'cardColorValue': serializer.toJson<int>(cardColorValue),
      'isDefault': serializer.toJson<bool>(isDefault),
      'statementDay': serializer.toJson<int?>(statementDay),
    };
  }

  PaymentMethodEntry copyWith({
    String? id,
    String? nickname,
    String? type,
    String? brand,
    String? last4,
    String? expiryDate,
    int? cardColorValue,
    bool? isDefault,
    Value<int?> statementDay = const Value.absent(),
  }) => PaymentMethodEntry(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    type: type ?? this.type,
    brand: brand ?? this.brand,
    last4: last4 ?? this.last4,
    expiryDate: expiryDate ?? this.expiryDate,
    cardColorValue: cardColorValue ?? this.cardColorValue,
    isDefault: isDefault ?? this.isDefault,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
  );
  PaymentMethodEntry copyWithCompanion(PaymentMethodsTableCompanion data) {
    return PaymentMethodEntry(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      type: data.type.present ? data.type.value : this.type,
      brand: data.brand.present ? data.brand.value : this.brand,
      last4: data.last4.present ? data.last4.value : this.last4,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      cardColorValue: data.cardColorValue.present
          ? data.cardColorValue.value
          : this.cardColorValue,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodEntry(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('type: $type, ')
          ..write('brand: $brand, ')
          ..write('last4: $last4, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('cardColorValue: $cardColorValue, ')
          ..write('isDefault: $isDefault, ')
          ..write('statementDay: $statementDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nickname,
    type,
    brand,
    last4,
    expiryDate,
    cardColorValue,
    isDefault,
    statementDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodEntry &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.type == this.type &&
          other.brand == this.brand &&
          other.last4 == this.last4 &&
          other.expiryDate == this.expiryDate &&
          other.cardColorValue == this.cardColorValue &&
          other.isDefault == this.isDefault &&
          other.statementDay == this.statementDay);
}

class PaymentMethodsTableCompanion extends UpdateCompanion<PaymentMethodEntry> {
  final Value<String> id;
  final Value<String> nickname;
  final Value<String> type;
  final Value<String> brand;
  final Value<String> last4;
  final Value<String> expiryDate;
  final Value<int> cardColorValue;
  final Value<bool> isDefault;
  final Value<int?> statementDay;
  final Value<int> rowid;
  const PaymentMethodsTableCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.type = const Value.absent(),
    this.brand = const Value.absent(),
    this.last4 = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.cardColorValue = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsTableCompanion.insert({
    required String id,
    required String nickname,
    required String type,
    required String brand,
    this.last4 = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.cardColorValue = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nickname = Value(nickname),
       type = Value(type),
       brand = Value(brand);
  static Insertable<PaymentMethodEntry> custom({
    Expression<String>? id,
    Expression<String>? nickname,
    Expression<String>? type,
    Expression<String>? brand,
    Expression<String>? last4,
    Expression<String>? expiryDate,
    Expression<int>? cardColorValue,
    Expression<bool>? isDefault,
    Expression<int>? statementDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (type != null) 'type': type,
      if (brand != null) 'brand': brand,
      if (last4 != null) 'last4': last4,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (cardColorValue != null) 'card_color_value': cardColorValue,
      if (isDefault != null) 'is_default': isDefault,
      if (statementDay != null) 'statement_day': statementDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? nickname,
    Value<String>? type,
    Value<String>? brand,
    Value<String>? last4,
    Value<String>? expiryDate,
    Value<int>? cardColorValue,
    Value<bool>? isDefault,
    Value<int?>? statementDay,
    Value<int>? rowid,
  }) {
    return PaymentMethodsTableCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryDate: expiryDate ?? this.expiryDate,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      isDefault: isDefault ?? this.isDefault,
      statementDay: statementDay ?? this.statementDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<String>(expiryDate.value);
    }
    if (cardColorValue.present) {
      map['card_color_value'] = Variable<int>(cardColorValue.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsTableCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('type: $type, ')
          ..write('brand: $brand, ')
          ..write('last4: $last4, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('cardColorValue: $cardColorValue, ')
          ..write('isDefault: $isDefault, ')
          ..write('statementDay: $statementDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingEntry extends DataClass implements Insertable<AppSettingEntry> {
  final String key;
  final String value;
  const AppSettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingEntry copyWith({String? key, String? value}) =>
      AppSettingEntry(key: key ?? this.key, value: value ?? this.value);
  AppSettingEntry copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubscriptionsTableTable subscriptionsTable =
      $SubscriptionsTableTable(this);
  late final $PaymentMethodsTableTable paymentMethodsTable =
      $PaymentMethodsTableTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subscriptionsTable,
    paymentMethodsTable,
    appSettingsTable,
  ];
}

typedef $$SubscriptionsTableTableCreateCompanionBuilder =
    SubscriptionsTableCompanion Function({
      required String id,
      required String name,
      required String description,
      required double price,
      Value<String> currency,
      required String billingCycle,
      required String category,
      required int brandColorValue,
      Value<int?> iconCodePoint,
      Value<String?> iconFontFamily,
      required DateTime nextBillingDate,
      required String status,
      required String paymentMethod,
      Value<String?> paymentMethodId,
      Value<int> reminderDays,
      Value<bool> isPopular,
      Value<String> notes,
      Value<List<DateTime>> paymentHistory,
      Value<String> accountUrl,
      Value<String?> logoUrl,
      Value<String?> brandPresetId,
      Value<bool> autoRenew,
      Value<int?> anchorDay,
      Value<int?> reminderTimeMinutes,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableTableUpdateCompanionBuilder =
    SubscriptionsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<double> price,
      Value<String> currency,
      Value<String> billingCycle,
      Value<String> category,
      Value<int> brandColorValue,
      Value<int?> iconCodePoint,
      Value<String?> iconFontFamily,
      Value<DateTime> nextBillingDate,
      Value<String> status,
      Value<String> paymentMethod,
      Value<String?> paymentMethodId,
      Value<int> reminderDays,
      Value<bool> isPopular,
      Value<String> notes,
      Value<List<DateTime>> paymentHistory,
      Value<String> accountUrl,
      Value<String?> logoUrl,
      Value<String?> brandPresetId,
      Value<bool> autoRenew,
      Value<int?> anchorDay,
      Value<int?> reminderTimeMinutes,
      Value<int> rowid,
    });

class $$SubscriptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get brandColorValue => $composableBuilder(
    column: $table.brandColorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconFontFamily => $composableBuilder(
    column: $table.iconFontFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextBillingDate => $composableBuilder(
    column: $table.nextBillingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethodId => $composableBuilder(
    column: $table.paymentMethodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderDays => $composableBuilder(
    column: $table.reminderDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPopular => $composableBuilder(
    column: $table.isPopular,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<DateTime>, List<DateTime>, String>
  get paymentHistory => $composableBuilder(
    column: $table.paymentHistory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get accountUrl => $composableBuilder(
    column: $table.accountUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandPresetId => $composableBuilder(
    column: $table.brandPresetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoRenew => $composableBuilder(
    column: $table.autoRenew,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorDay => $composableBuilder(
    column: $table.anchorDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderTimeMinutes => $composableBuilder(
    column: $table.reminderTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get brandColorValue => $composableBuilder(
    column: $table.brandColorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconFontFamily => $composableBuilder(
    column: $table.iconFontFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextBillingDate => $composableBuilder(
    column: $table.nextBillingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethodId => $composableBuilder(
    column: $table.paymentMethodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderDays => $composableBuilder(
    column: $table.reminderDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPopular => $composableBuilder(
    column: $table.isPopular,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentHistory => $composableBuilder(
    column: $table.paymentHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountUrl => $composableBuilder(
    column: $table.accountUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandPresetId => $composableBuilder(
    column: $table.brandPresetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoRenew => $composableBuilder(
    column: $table.autoRenew,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorDay => $composableBuilder(
    column: $table.anchorDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderTimeMinutes => $composableBuilder(
    column: $table.reminderTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get brandColorValue => $composableBuilder(
    column: $table.brandColorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconFontFamily => $composableBuilder(
    column: $table.iconFontFamily,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextBillingDate => $composableBuilder(
    column: $table.nextBillingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethodId => $composableBuilder(
    column: $table.paymentMethodId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderDays => $composableBuilder(
    column: $table.reminderDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPopular =>
      $composableBuilder(column: $table.isPopular, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<DateTime>, String> get paymentHistory =>
      $composableBuilder(
        column: $table.paymentHistory,
        builder: (column) => column,
      );

  GeneratedColumn<String> get accountUrl => $composableBuilder(
    column: $table.accountUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get brandPresetId => $composableBuilder(
    column: $table.brandPresetId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoRenew =>
      $composableBuilder(column: $table.autoRenew, builder: (column) => column);

  GeneratedColumn<int> get anchorDay =>
      $composableBuilder(column: $table.anchorDay, builder: (column) => column);

  GeneratedColumn<int> get reminderTimeMinutes => $composableBuilder(
    column: $table.reminderTimeMinutes,
    builder: (column) => column,
  );
}

class $$SubscriptionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTableTable,
          SubscriptionEntry,
          $$SubscriptionsTableTableFilterComposer,
          $$SubscriptionsTableTableOrderingComposer,
          $$SubscriptionsTableTableAnnotationComposer,
          $$SubscriptionsTableTableCreateCompanionBuilder,
          $$SubscriptionsTableTableUpdateCompanionBuilder,
          (
            SubscriptionEntry,
            BaseReferences<
              _$AppDatabase,
              $SubscriptionsTableTable,
              SubscriptionEntry
            >,
          ),
          SubscriptionEntry,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableTableManager(
    _$AppDatabase db,
    $SubscriptionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> billingCycle = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> brandColorValue = const Value.absent(),
                Value<int?> iconCodePoint = const Value.absent(),
                Value<String?> iconFontFamily = const Value.absent(),
                Value<DateTime> nextBillingDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> paymentMethodId = const Value.absent(),
                Value<int> reminderDays = const Value.absent(),
                Value<bool> isPopular = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<List<DateTime>> paymentHistory = const Value.absent(),
                Value<String> accountUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> brandPresetId = const Value.absent(),
                Value<bool> autoRenew = const Value.absent(),
                Value<int?> anchorDay = const Value.absent(),
                Value<int?> reminderTimeMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsTableCompanion(
                id: id,
                name: name,
                description: description,
                price: price,
                currency: currency,
                billingCycle: billingCycle,
                category: category,
                brandColorValue: brandColorValue,
                iconCodePoint: iconCodePoint,
                iconFontFamily: iconFontFamily,
                nextBillingDate: nextBillingDate,
                status: status,
                paymentMethod: paymentMethod,
                paymentMethodId: paymentMethodId,
                reminderDays: reminderDays,
                isPopular: isPopular,
                notes: notes,
                paymentHistory: paymentHistory,
                accountUrl: accountUrl,
                logoUrl: logoUrl,
                brandPresetId: brandPresetId,
                autoRenew: autoRenew,
                anchorDay: anchorDay,
                reminderTimeMinutes: reminderTimeMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required double price,
                Value<String> currency = const Value.absent(),
                required String billingCycle,
                required String category,
                required int brandColorValue,
                Value<int?> iconCodePoint = const Value.absent(),
                Value<String?> iconFontFamily = const Value.absent(),
                required DateTime nextBillingDate,
                required String status,
                required String paymentMethod,
                Value<String?> paymentMethodId = const Value.absent(),
                Value<int> reminderDays = const Value.absent(),
                Value<bool> isPopular = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<List<DateTime>> paymentHistory = const Value.absent(),
                Value<String> accountUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> brandPresetId = const Value.absent(),
                Value<bool> autoRenew = const Value.absent(),
                Value<int?> anchorDay = const Value.absent(),
                Value<int?> reminderTimeMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                price: price,
                currency: currency,
                billingCycle: billingCycle,
                category: category,
                brandColorValue: brandColorValue,
                iconCodePoint: iconCodePoint,
                iconFontFamily: iconFontFamily,
                nextBillingDate: nextBillingDate,
                status: status,
                paymentMethod: paymentMethod,
                paymentMethodId: paymentMethodId,
                reminderDays: reminderDays,
                isPopular: isPopular,
                notes: notes,
                paymentHistory: paymentHistory,
                accountUrl: accountUrl,
                logoUrl: logoUrl,
                brandPresetId: brandPresetId,
                autoRenew: autoRenew,
                anchorDay: anchorDay,
                reminderTimeMinutes: reminderTimeMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTableTable,
      SubscriptionEntry,
      $$SubscriptionsTableTableFilterComposer,
      $$SubscriptionsTableTableOrderingComposer,
      $$SubscriptionsTableTableAnnotationComposer,
      $$SubscriptionsTableTableCreateCompanionBuilder,
      $$SubscriptionsTableTableUpdateCompanionBuilder,
      (
        SubscriptionEntry,
        BaseReferences<
          _$AppDatabase,
          $SubscriptionsTableTable,
          SubscriptionEntry
        >,
      ),
      SubscriptionEntry,
      PrefetchHooks Function()
    >;
typedef $$PaymentMethodsTableTableCreateCompanionBuilder =
    PaymentMethodsTableCompanion Function({
      required String id,
      required String nickname,
      required String type,
      required String brand,
      Value<String> last4,
      Value<String> expiryDate,
      Value<int> cardColorValue,
      Value<bool> isDefault,
      Value<int?> statementDay,
      Value<int> rowid,
    });
typedef $$PaymentMethodsTableTableUpdateCompanionBuilder =
    PaymentMethodsTableCompanion Function({
      Value<String> id,
      Value<String> nickname,
      Value<String> type,
      Value<String> brand,
      Value<String> last4,
      Value<String> expiryDate,
      Value<int> cardColorValue,
      Value<bool> isDefault,
      Value<int?> statementDay,
      Value<int> rowid,
    });

class $$PaymentMethodsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardColorValue => $composableBuilder(
    column: $table.cardColorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentMethodsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardColorValue => $composableBuilder(
    column: $table.cardColorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentMethodsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cardColorValue => $composableBuilder(
    column: $table.cardColorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => column,
  );
}

class $$PaymentMethodsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentMethodsTableTable,
          PaymentMethodEntry,
          $$PaymentMethodsTableTableFilterComposer,
          $$PaymentMethodsTableTableOrderingComposer,
          $$PaymentMethodsTableTableAnnotationComposer,
          $$PaymentMethodsTableTableCreateCompanionBuilder,
          $$PaymentMethodsTableTableUpdateCompanionBuilder,
          (
            PaymentMethodEntry,
            BaseReferences<
              _$AppDatabase,
              $PaymentMethodsTableTable,
              PaymentMethodEntry
            >,
          ),
          PaymentMethodEntry,
          PrefetchHooks Function()
        > {
  $$PaymentMethodsTableTableTableManager(
    _$AppDatabase db,
    $PaymentMethodsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PaymentMethodsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> last4 = const Value.absent(),
                Value<String> expiryDate = const Value.absent(),
                Value<int> cardColorValue = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsTableCompanion(
                id: id,
                nickname: nickname,
                type: type,
                brand: brand,
                last4: last4,
                expiryDate: expiryDate,
                cardColorValue: cardColorValue,
                isDefault: isDefault,
                statementDay: statementDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nickname,
                required String type,
                required String brand,
                Value<String> last4 = const Value.absent(),
                Value<String> expiryDate = const Value.absent(),
                Value<int> cardColorValue = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsTableCompanion.insert(
                id: id,
                nickname: nickname,
                type: type,
                brand: brand,
                last4: last4,
                expiryDate: expiryDate,
                cardColorValue: cardColorValue,
                isDefault: isDefault,
                statementDay: statementDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentMethodsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentMethodsTableTable,
      PaymentMethodEntry,
      $$PaymentMethodsTableTableFilterComposer,
      $$PaymentMethodsTableTableOrderingComposer,
      $$PaymentMethodsTableTableAnnotationComposer,
      $$PaymentMethodsTableTableCreateCompanionBuilder,
      $$PaymentMethodsTableTableUpdateCompanionBuilder,
      (
        PaymentMethodEntry,
        BaseReferences<
          _$AppDatabase,
          $PaymentMethodsTableTable,
          PaymentMethodEntry
        >,
      ),
      PaymentMethodEntry,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableTableCreateCompanionBuilder =
    AppSettingsTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableTableUpdateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTableTable,
          AppSettingEntry,
          $$AppSettingsTableTableFilterComposer,
          $$AppSettingsTableTableOrderingComposer,
          $$AppSettingsTableTableAnnotationComposer,
          $$AppSettingsTableTableCreateCompanionBuilder,
          $$AppSettingsTableTableUpdateCompanionBuilder,
          (
            AppSettingEntry,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsTableTable,
              AppSettingEntry
            >,
          ),
          AppSettingEntry,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableTableManager(
    _$AppDatabase db,
    $AppSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsTableCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTableTable,
      AppSettingEntry,
      $$AppSettingsTableTableFilterComposer,
      $$AppSettingsTableTableOrderingComposer,
      $$AppSettingsTableTableAnnotationComposer,
      $$AppSettingsTableTableCreateCompanionBuilder,
      $$AppSettingsTableTableUpdateCompanionBuilder,
      (
        AppSettingEntry,
        BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingEntry>,
      ),
      AppSettingEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubscriptionsTableTableTableManager get subscriptionsTable =>
      $$SubscriptionsTableTableTableManager(_db, _db.subscriptionsTable);
  $$PaymentMethodsTableTableTableManager get paymentMethodsTable =>
      $$PaymentMethodsTableTableTableManager(_db, _db.paymentMethodsTable);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
}
