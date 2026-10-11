/// Semantic funnel status for a job application in the Kanban board.
enum JobStatus {
  /// Newly discovered / saved vacancy.
  newJob('new', 'Nova'),

  /// Applied vacancy with CV / form sent.
  applied('applied', 'Candidatado'),

  /// Screening, technical or cultural interview stage.
  interview('interviewing', 'Entrevista'),

  /// Job proposal / job offer received.
  offer('offer', 'Proposta'),

  /// Rejected or closed by applicant/company.
  rejected('rejected', 'Rejeitada');

  const JobStatus(this.value, this.label);

  /// Raw database string value used in Supabase.
  final String value;

  /// Human-friendly display label.
  final String label;

  /// Parses a string into a [JobStatus] with resilient fallback to [JobStatus.newJob].
  static JobStatus fromString(String? raw) {
    if (raw == null) return JobStatus.newJob;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'interview' || normalized == 'interviewing') {
      return JobStatus.interview;
    }
    for (final status in JobStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    // Fallback gracioso para status padrão
    return JobStatus.newJob;
  }
}
