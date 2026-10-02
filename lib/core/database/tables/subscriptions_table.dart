import 'package:drift/drift.dart';
import '../converters/date_time_list_converter.dart';

@DataClassName('SubscriptionEntry')
class SubscriptionsTable extends Table {
  @override
  String get tableName => 'subscriptions';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get price => real()();
  /// ISO 4217 code (schema v3; earlier versions stored a display symbol such as `$`).
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get billingCycle => text()();
  TextColumn get category => text()();
  IntColumn get brandColorValue => integer()();
  IntColumn get iconCodePoint => integer().nullable()();
  TextColumn get iconFontFamily => text().nullable()();
  DateTimeColumn get nextBillingDate => dateTime()();
  TextColumn get status => text()();
  TextColumn get paymentMethod => text()();
  TextColumn get paymentMethodId => text().nullable()();
  IntColumn get reminderDays => integer().withDefault(const Constant(2))();
  BoolColumn get isPopular => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get paymentHistory => text().map(const DateTimeListConverter()).withDefault(const Constant('[]'))();
  TextColumn get accountUrl => text().withDefault(const Constant(''))();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get brandPresetId => text().nullable()();
  BoolColumn get autoRenew => boolean().withDefault(const Constant(true))();
  IntColumn get anchorDay => integer().nullable()();

  /// Added in schema v2: reminder time of day in minutes after midnight (null = global default).
  IntColumn get reminderTimeMinutes => integer().nullable()();

  /// Custom logo framing ("scale,dx,dy", see LogoTransform). Added in schema v4.
  TextColumn get logoTransform => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
