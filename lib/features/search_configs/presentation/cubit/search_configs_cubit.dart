import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/search_config.dart';
import '../../domain/models/search_config_category.dart';
import '../../domain/repositories/search_configs_repository.dart';
import 'search_configs_state.dart';

/// Cubit managing search configurations state and asynchronous mutations.
class SearchConfigsCubit extends Cubit<SearchConfigsState> {
  SearchConfigsCubit(this._repository) : super(const SearchConfigsInitial());

  final SearchConfigsRepository _repository;

  /// Exposes the underlying repository.
  SearchConfigsRepository get repository => _repository;

  /// Loads all search configs from the repository.
  Future<void> loadConfigs() async {
    emit(const SearchConfigsLoading());
    try {
      final configs = await _repository.getConfigs();
      emit(SearchConfigsLoaded(configs));
    } catch (e) {
      emit(SearchConfigsError('Erro ao carregar critérios de busca: $e'));
    }
  }

  /// Adds a new search config with validation.
  Future<void> addConfig(SearchConfig config) async {
    final cleanValue = config.value.trim();
    if (cleanValue.isEmpty) {
      return;
    }
    final normalized = config.copyWith(value: cleanValue);
    try {
      await _repository.addConfig(normalized);
      await loadConfigs();
    } catch (e) {
      emit(SearchConfigsError('Erro ao adicionar critério: $e'));
    }
  }

  /// Adds a new search criterion by category and text value.
  Future<void> addTerm({
    required SearchConfigCategory category,
    required String value,
  }) async {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) return;

    await addConfig(
      SearchConfig(
        id: '',
        category: category,
        value: cleanValue,
        isActive: true,
      ),
    );
  }

  /// Toggles active status of a config record.
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _repository.toggleActive(id, isActive);
      await loadConfigs();
    } catch (e) {
      emit(SearchConfigsError('Erro ao alterar status: $e'));
    }
  }

  /// Deletes a config by its identifier.
  Future<void> deleteConfig(String id) async {
    try {
      await _repository.deleteConfig(id);
      await loadConfigs();
    } catch (e) {
      emit(SearchConfigsError('Erro ao excluir critério: $e'));
    }
  }
}
