import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/search_config.dart';
import '../../domain/repositories/search_configs_repository.dart';
import 'search_configs_state.dart';

/// Cubit managing search configurations state.
class SearchConfigsCubit extends Cubit<SearchConfigsState> {
  SearchConfigsCubit(this._repository) : super(const SearchConfigsInitial());

  final SearchConfigsRepository _repository;

  /// Loads all search configs.
  Future<void> loadConfigs() async {
    emit(const SearchConfigsLoading());
    try {
      final configs = await _repository.getConfigs();
      emit(SearchConfigsLoaded(configs));
    } catch (e) {
      emit(SearchConfigsError('Erro ao carregar critérios de busca: $e'));
    }
  }

  /// Adds a new search config.
  Future<void> addConfig(SearchConfig config) async {
    try {
      await _repository.addConfig(config);
      await loadConfigs();
    } catch (e) {
      emit(SearchConfigsError('Erro ao adicionar critério: $e'));
    }
  }

  /// Toggles active status of a config.
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _repository.toggleActive(id, isActive);
      await loadConfigs();
    } catch (e) {
      emit(SearchConfigsError('Erro ao alterar status: $e'));
    }
  }

  /// Deletes a config.
  Future<void> deleteConfig(String id) async {
    try {
      await _repository.deleteConfig(id);
      await loadConfigs();
    } catch (e) {
      emit(SearchConfigsError('Erro ao excluir critério: $e'));
    }
  }
}
