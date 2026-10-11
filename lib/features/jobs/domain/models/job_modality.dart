/// Work modalities supported for filtering job listings in the Kanban board.
enum JobModalityFilter {
  all('all', 'Todos'),
  remote('remote', 'Remoto'),
  hybrid('hybrid', 'Híbrido'),
  onSite('presencial', 'Presencial');

  const JobModalityFilter(this.value, this.label);

  /// Internal identifier value.
  final String value;

  /// Human-friendly display label shown in filter chips.
  final String label;

  /// Parses a raw string into [JobModalityFilter] with resilient fallback to [all].
  static JobModalityFilter fromString(String? raw) {
    if (raw == null) return JobModalityFilter.all;
    final normalized = raw.trim().toLowerCase();
    for (final modality in JobModalityFilter.values) {
      if (modality.value == normalized ||
          modality.label.toLowerCase() == normalized) {
        return modality;
      }
    }
    return JobModalityFilter.all;
  }
}
