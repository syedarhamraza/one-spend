import 'package:drift/drift.dart';

@DataClassName('PaymentMethodEntry')
class PaymentMethodsTable extends Table {
  @override
  String get tableName => 'payment_methods';

  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get type => text()();
  TextColumn get brand => text()();
  TextColumn get last4 => text().withDefault(const Constant(''))();
  TextColumn get expiryDate => text().withDefault(const Constant(''))();
  IntColumn get cardColorValue => integer().withDefault(const Constant(0xFF2C3440))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get statementDay => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
