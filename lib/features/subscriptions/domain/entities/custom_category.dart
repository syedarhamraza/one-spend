/// A user-made subscription category (Pro). Subscriptions refer to it by [id]
/// through `SubscriptionCategory.custom(id)`.
class CustomCategory {
  static const idPrefix = 'c_';

  final String id;
  final String name;

  /// A glyph from the app's known icon set (see `supportedSubscriptionIcons`).
  final int iconCodePoint;
  final int colorValue;
  final int sortOrder;

  const CustomCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.sortOrder = 0,
  });

  static bool isCustomId(String id) => id.startsWith(idPrefix);

  static String newId() => '$idPrefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  CustomCategory copyWith({String? name, int? iconCodePoint, int? colorValue, int? sortOrder}) => CustomCategory(
        id: id,
        name: name ?? this.name,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        colorValue: colorValue ?? this.colorValue,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'sortOrder': sortOrder,
      };

  factory CustomCategory.fromJson(Map<String, dynamic> json) => CustomCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        iconCodePoint: (json['iconCodePoint'] as num).toInt(),
        colorValue: (json['colorValue'] as num).toInt(),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is CustomCategory &&
      other.id == id &&
      other.name == name &&
      other.iconCodePoint == iconCodePoint &&
      other.colorValue == colorValue &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(id, name, iconCodePoint, colorValue, sortOrder);
}

/// The custom categories currently loaded, so a `SubscriptionCategory` can resolve its
/// name, icon and colour. `SubscriptionController` keeps it in sync.
class CustomCategoryRegistry {
  const CustomCategoryRegistry._();

  static List<CustomCategory> _categories = const [];
  static Map<String, CustomCategory> _byId = const {};

  /// In display order.
  static List<CustomCategory> get categories => _categories;

  static CustomCategory? byId(String id) => _byId[id];

  static void replaceAll(Iterable<CustomCategory> categories) {
    _categories = List.unmodifiable(categories.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
    _byId = {for (final c in _categories) c.id: c};
  }
}
