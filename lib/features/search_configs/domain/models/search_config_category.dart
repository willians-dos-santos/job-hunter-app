/// Category for job search filtering criteria.
enum SearchConfigCategory {
  /// Positive keyword match (e.g. "Flutter", "Dart", "Tech Lead").
  keyword('keyword', 'Palavra-chave'),

  /// Negative keyword to exclude (e.g. "Senior PHP", "Presencial").
  excluded('excluded', 'Exclusão'),

  /// Location filter (e.g. "Remoto", "São Paulo", "Brasil").
  location('location', 'Localização'),

  /// Target or blocked company name.
  company('company', 'Empresa');

  const SearchConfigCategory(this.value, this.label);

  /// Database value stored in Supabase `search_configs`.
  final String value;

  /// Display label in Portuguese.
  final String label;

  /// Parses a category string, defaulting resiliently to [SearchConfigCategory.keyword].
  static SearchConfigCategory fromString(String? raw) {
    if (raw == null) return SearchConfigCategory.keyword;
    final normalized = raw.trim().toLowerCase();
    for (final category in SearchConfigCategory.values) {
      if (category.value == normalized) {
        return category;
      }
    }
    // Fallback gracioso para categoria padrão
    return SearchConfigCategory.keyword;
  }
}
