/// Category for job search filtering criteria.
///
/// Matches the check constraint on `public.search_configs.category`:
/// `'keyword'`, `'excluded_keyword'`, `'location'`, `'company'`, `'ats_filter'`.
enum SearchConfigCategory {
  /// Positive keyword match (e.g. "Flutter", "Dart", "Tech Lead").
  keyword('keyword', 'Palavra-chave'),

  /// Negative keyword to exclude (e.g. "Senior PHP", "Presencial").
  excludedKeyword('excluded_keyword', 'Termo Excluído'),

  /// ATS platform filter (e.g. "greenhouse", "lever", "gupy").
  atsFilter('ats_filter', 'Filtro ATS'),

  /// Location filter (e.g. "Remoto", "São Paulo", "Brasil").
  location('location', 'Localização'),

  /// Target or blocked company name.
  company('company', 'Empresa');

  const SearchConfigCategory(this.value, this.label);

  /// Database value stored in Supabase `search_configs`.
  final String value;

  /// Display label in Portuguese.
  final String label;

  /// Backwards-compatible alias for [excludedKeyword].
  static const SearchConfigCategory excluded = excludedKeyword;

  /// Parses a category string, defaulting resiliently to [SearchConfigCategory.keyword].
  static SearchConfigCategory fromString(String? raw) {
    if (raw == null) return SearchConfigCategory.keyword;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'excluded' || normalized == 'excluded_keyword') {
      return SearchConfigCategory.excludedKeyword;
    }
    if (normalized == 'ats_filter' ||
        normalized == 'atsfilter' ||
        normalized == 'ats') {
      return SearchConfigCategory.atsFilter;
    }
    for (final category in SearchConfigCategory.values) {
      if (category.value == normalized) {
        return category;
      }
    }
    // Fallback gracioso para categoria padrão
    return SearchConfigCategory.keyword;
  }
}
