import 'package:flutter/foundation.dart';

import '../../domain/models/search_config.dart';

/// Base state for search configs presentation.
@immutable
sealed class SearchConfigsState {
  const SearchConfigsState();
}

/// Initial state.
final class SearchConfigsInitial extends SearchConfigsState {
  const SearchConfigsInitial();
}

/// Loading state.
final class SearchConfigsLoading extends SearchConfigsState {
  const SearchConfigsLoading();
}

/// Loaded state containing current search configs.
final class SearchConfigsLoaded extends SearchConfigsState {
  const SearchConfigsLoaded(this.configs);

  final List<SearchConfig> configs;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchConfigsLoaded && listEquals(other.configs, configs);
  }

  @override
  int get hashCode => configs.hashCode;
}

/// Error state.
final class SearchConfigsError extends SearchConfigsState {
  const SearchConfigsError(this.message);

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchConfigsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
