import 'package:flutter/foundation.dart';

import 'search_config_category.dart';

/// Represents a user search configuration or filtering criteria stored in `public.search_configs`.
@immutable
class SearchConfig {
  const SearchConfig({
    required this.id,
    required this.category,
    required this.value,
    this.isActive = true,
    this.userId,
    this.metadata,
  });

  /// Factory parser for records from `public.search_configs`.
  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawCategory = json['category'];
    final rawValue = json['value'];
    final rawIsActive = json['is_active'] ?? json['isActive'];
    final rawUserId = json['user_id'] ?? json['userId'];
    final rawMetadata = json['metadata'];

    return SearchConfig(
      id: rawId?.toString() ?? '',
      category: SearchConfigCategory.fromString(rawCategory?.toString()),
      value: rawValue?.toString() ?? '',
      isActive: rawIsActive is bool ? rawIsActive : true,
      userId: rawUserId?.toString(),
      metadata: rawMetadata is Map<String, dynamic> ? rawMetadata : null,
    );
  }

  /// Unique record identifier (UUID string or int).
  final String id;

  /// Category of the search configuration.
  final SearchConfigCategory category;

  /// String value or expression for the rule.
  final String value;

  /// Whether this filter rule is actively applied.
  final bool isActive;

  /// Associated Supabase user ID (UUID).
  final String? userId;

  /// Additional metadata payload in JSON.
  final Map<String, dynamic>? metadata;

  /// Converts this entity into a JSON map suitable for Supabase queries and mutations.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      if (userId != null && userId!.isNotEmpty) 'user_id': userId,
      'category': category.value,
      'value': value,
      'is_active': isActive,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Returns a copy of this [SearchConfig] with the given fields replaced.
  SearchConfig copyWith({
    String? id,
    SearchConfigCategory? category,
    String? value,
    bool? isActive,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return SearchConfig(
      id: id ?? this.id,
      category: category ?? this.category,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchConfig &&
        other.id == id &&
        other.category == category &&
        other.value == value &&
        other.isActive == isActive &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, category, value, isActive, userId);

  @override
  String toString() {
    return 'SearchConfig(id: $id, category: ${category.value}, value: $value, isActive: $isActive)';
  }
}
