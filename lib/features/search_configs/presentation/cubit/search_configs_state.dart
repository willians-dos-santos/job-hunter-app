import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/search_config.dart';
import '../../domain/models/search_config_category.dart';

/// Base state for search configs presentation with Equatable immutability.
@immutable
sealed class SearchConfigsState extends Equatable {
  const SearchConfigsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before configurations are requested.
final class SearchConfigsInitial extends SearchConfigsState {
  const SearchConfigsInitial();
}

/// Loading state emitted while querying or mutating search configs.
final class SearchConfigsLoading extends SearchConfigsState {
  const SearchConfigsLoading();
}

/// Loaded state containing current search configs and optional user notifications.
final class SearchConfigsLoaded extends SearchConfigsState {
  const SearchConfigsLoaded(this.configs, {this.actionMessage});

  /// All current search configurations.
  final List<SearchConfig> configs;

  /// Optional transient notification message (e.g. feedback on added or removed terms).
  final String? actionMessage;

  /// Filters configurations by a specific [category].
  List<SearchConfig> getByCategory(SearchConfigCategory category) =>
      configs.where((c) => c.category == category).toList();

  /// Total count of actively enabled configurations.
  int get activeCount => configs.where((c) => c.isActive).length;

  /// True if there are zero search criteria registered.
  bool get isEmpty => configs.isEmpty;

  SearchConfigsLoaded copyWith({
    List<SearchConfig>? configs,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return SearchConfigsLoaded(
      configs ?? this.configs,
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [configs, actionMessage];
}

/// Error state emitted when a repository operation fails.
final class SearchConfigsError extends SearchConfigsState {
  const SearchConfigsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
