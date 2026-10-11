import 'package:flutter/foundation.dart';

import 'search_config_category.dart';

/// Represents a user search configuration or filtering criteria stored in `search_configs`.
@immutable
class SearchConfig {
  const SearchConfig({
    required this.id,
    required this.category,
    required this.value,
    this.isActive = true,
  });

  /// Factory parser for records from `search_configs`.
  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawCategory = json['category'];
    final rawValue = json['value'];
    final rawIsActive = json['is_active'] ?? json['isActive'];

    return SearchConfig(
      id: rawId?.toString() ?? '',
      category: SearchConfigCategory.fromString(rawCategory?.toString()),
      value: rawValue?.toString() ?? '',
      isActive: rawIsActive is bool ? rawIsActive : true,
    );
  }

  /// Unique record identifier (int or UUID string).
  final String id;

  /// Category of the search configuration.
  final SearchConfigCategory category;

  /// String value or expression for the rule.
  final String value;

  /// Whether this filter rule is actively applied.
  final bool isActive;

  /// Converts this entity into a JSON map suitable for Supabase queries.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      'category': category.value,
      'value': value,
      'is_active': isActive,
    };
  }

  /// Returns a copy of this [SearchConfig] with the given fields replaced.
  SearchConfig copyWith({
    String? id,
    SearchConfigCategory? category,
    String? value,
    bool? isActive,
  }) {
    return SearchConfig(
      id: id ?? this.id,
      category: category ?? this.category,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchConfig &&
        other.id == id &&
        other.category == category &&
        other.value == value &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, category, value, isActive);

  @override
  String toString() {
    return 'SearchConfig(id: $id, category: ${category.value}, value: $value, isActive: $isActive)';
  }
}
