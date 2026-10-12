import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/repositories/search_configs_repository_impl.dart';
import '../../domain/models/search_config.dart';
import '../../domain/models/search_config_category.dart';
import '../../domain/repositories/search_configs_repository.dart';
import '../cubit/search_configs_cubit.dart';
import '../cubit/search_configs_state.dart';

/// Screen for managing job search and filtering criteria with category chip groups.
class SearchConfigsScreen extends StatefulWidget {
  const SearchConfigsScreen({
    super.key,
    this.cubit,
    this.repository,
  });

  final SearchConfigsCubit? cubit;
  final SearchConfigsRepository? repository;

  @override
  State<SearchConfigsScreen> createState() => _SearchConfigsScreenState();
}

class _SearchConfigsScreenState extends State<SearchConfigsScreen> {
  late final SearchConfigsCubit _cubit;
  late final TextEditingController _inputController;
  bool _ownsCubit = false;

  SearchConfigCategory _selectedCategory = SearchConfigCategory.keyword;

  static const List<SearchConfigCategory> _displayCategories = [
    SearchConfigCategory.keyword,
    SearchConfigCategory.excludedKeyword,
    SearchConfigCategory.atsFilter,
    SearchConfigCategory.location,
  ];

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();

    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      _cubit = SearchConfigsCubit(
        widget.repository ?? SearchConfigsRepositoryImpl(),
      );
      _ownsCubit = true;
      _cubit.loadConfigs();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _submitAdd() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _cubit.addTerm(category: _selectedCategory, value: text);
    _inputController.clear();
    setState(() {});
  }

  String _getHintForCategory(SearchConfigCategory category) {
    switch (category) {
      case SearchConfigCategory.keyword:
        return 'ex: Flutter, Dart, Tech Lead...';
      case SearchConfigCategory.excludedKeyword:
        return 'ex: Presencial, PHP Sênior, Trainee...';
      case SearchConfigCategory.atsFilter:
        return 'ex: greenhouse, lever, gupy, workable...';
      case SearchConfigCategory.location:
        return 'ex: Remoto, São Paulo, Brasil, Híbrido...';
      case SearchConfigCategory.company:
        return 'ex: Google, Nubank, Mercado Livre...';
    }
  }

  Color _getColorForCategory(SearchConfigCategory category) {
    switch (category) {
      case SearchConfigCategory.keyword:
        return AppColors.terminalCyan;
      case SearchConfigCategory.excludedKeyword:
        return AppColors.kanbanRejected;
      case SearchConfigCategory.atsFilter:
        return AppColors.kanbanApplied;
      case SearchConfigCategory.location:
        return AppColors.kanbanOffer;
      case SearchConfigCategory.company:
        return AppColors.kanbanInterview;
    }
  }

  IconData _getIconForCategory(SearchConfigCategory category) {
    switch (category) {
      case SearchConfigCategory.keyword:
        return Icons.search_rounded;
      case SearchConfigCategory.excludedKeyword:
        return Icons.do_not_disturb_on_outlined;
      case SearchConfigCategory.atsFilter:
        return Icons.hub_outlined;
      case SearchConfigCategory.location:
        return Icons.location_on_outlined;
      case SearchConfigCategory.company:
        return Icons.business_outlined;
    }
  }

  String _getDescriptionForCategory(SearchConfigCategory category) {
    switch (category) {
      case SearchConfigCategory.keyword:
        return 'Termos de busca obrigatórios em títulos e descrições de vagas.';
      case SearchConfigCategory.excludedKeyword:
        return 'Vagas contendo qualquer um destes termos serão descartadas automaticamente.';
      case SearchConfigCategory.atsFilter:
        return 'Sistemas e plataformas ATS onde as vagas devem ser monitoradas.';
      case SearchConfigCategory.location:
        return 'Cidades, países ou modalidades de trabalho preferenciais.';
      case SearchConfigCategory.company:
        return 'Empresas monitoradas ou bloqueadas para candidatura.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.slate900,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withAlpha(45),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppColors.primaryIndigo.withAlpha(120)),
                ),
                child: Text(
                  'SEARCH-CONFIGS',
                  style: AppTypography.monoTag(color: AppColors.terminalCyan),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Critérios de Busca',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Recarregar critérios',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _cubit.loadConfigs(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocConsumer<SearchConfigsCubit, SearchConfigsState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state is SearchConfigsError) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.kanbanRejected,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SearchConfigsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.terminalCyan,
                ),
              );
            }

            if (state is SearchConfigsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate700),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.kanbanRejected,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Falha ao carregar critérios',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSlate400),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _cubit.loadConfigs(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryIndigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final loaded = state is SearchConfigsLoaded
                ? state
                : const SearchConfigsLoaded([]);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header informativo e contadores
                      _buildSummaryCard(loaded),
                      const SizedBox(height: 20),

                      // Formulário para adicionar novos termos
                      _buildAddTermCard(),
                      const SizedBox(height: 24),

                      // Grupos de categorias
                      ..._displayCategories.map((category) {
                        final items = loaded.getByCategory(category);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildCategoryGroupCard(category, items),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SearchConfigsLoaded loaded) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryIndigo.withAlpha(90)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.terminalCyan,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações Ativas do Crawler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estes critérios instruem o pipeline a coletar e filtrar vagas automaticamente no Supabase.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSlate300,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate850,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.kanbanOffer,
                ),
                const SizedBox(width: 6),
                Text(
                  '${loaded.activeCount} / ${loaded.configs.length} ativos',
                  style: AppTypography.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTermCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: AppColors.terminalCyan,
              ),
              const SizedBox(width: 8),
              Text(
                'Adicionar Novo Critério',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Seletor de Categoria
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _displayCategories.map((category) {
              final isSelected = _selectedCategory == category;
              final catColor = _getColorForCategory(category);
              return ChoiceChip(
                key: Key('category_chip_${category.value}'),
                label: Text(category.label),
                selected: isSelected,
                avatar: Icon(
                  _getIconForCategory(category),
                  size: 16,
                  color: isSelected ? catColor : AppColors.textSlate400,
                ),
                selectedColor: catColor.withAlpha(35),
                backgroundColor: AppColors.slate850,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? catColor : AppColors.slate700,
                  ),
                ),
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppColors.textWhite : AppColors.textSlate400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Campo de entrada e botão adicionar
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('add_term_input'),
                  controller: _inputController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitAdd(),
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: _getHintForCategory(_selectedCategory),
                    hintStyle: const TextStyle(color: AppColors.textSlate400),
                    filled: true,
                    fillColor: AppColors.slate850,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.slate700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.terminalCyan,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: _inputController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: AppColors.textSlate400,
                            ),
                            onPressed: () {
                              _inputController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                key: const Key('add_term_button'),
                onPressed:
                    _inputController.text.trim().isNotEmpty ? _submitAdd : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  backgroundColor: AppColors.primaryIndigo,
                  disabledBackgroundColor: AppColors.slate700,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.textSlate400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroupCard(
    SearchConfigCategory category,
    List<SearchConfig> items,
  ) {
    final catColor = _getColorForCategory(category);
    final activeCount = items.where((i) => i.isActive).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: catColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getIconForCategory(category),
                  size: 18,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          category.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.slate850,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.slate700),
                          ),
                          child: Text(
                            '$activeCount/${items.length} ativos',
                            style: AppTypography.mono(
                              fontSize: 10,
                              color: items.isEmpty
                                  ? AppColors.textSlate400
                                  : catColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDescriptionForCategory(category),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSlate400,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyCategoryPlaceholder(category)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((config) {
                return _buildChip(config, catColor);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(SearchConfig config, Color categoryColor) {
    final isActive = config.isActive;

    return Tooltip(
      message: isActive ? 'Toque para desativar' : 'Toque para ativar',
      child: InkWell(
        key: Key('chip_${config.category.value}_${config.value}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _cubit.toggleActive(config.id, !isActive),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? categoryColor.withAlpha(30)
                : AppColors.slate850.withAlpha(120),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? categoryColor.withAlpha(140)
                  : AppColors.slate700,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? categoryColor : AppColors.textSlate500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                config.value,
                style: TextStyle(
                  color:
                      isActive ? AppColors.textWhite : AppColors.textSlate400,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  decoration: isActive
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
                  decorationColor: AppColors.textSlate500,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                key: Key('delete_${config.category.value}_${config.value}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _cubit.deleteConfig(config.id),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isActive
                        ? AppColors.textWhite.withAlpha(180)
                        : AppColors.textSlate400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryPlaceholder(SearchConfigCategory category) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.slate850.withAlpha(150),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.slate700.withAlpha(100),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textSlate400.withAlpha(160),
          ),
          const SizedBox(width: 8),
          Text(
            'Nenhum termo cadastrado nesta categoria.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSlate400,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
