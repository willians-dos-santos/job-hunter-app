import 'package:flutter/material.dart';

import '../../features/jobs/domain/models/job_status.dart';
import 'app_colors.dart';

/// Semantic colors for the Kanban funnel stages exposed via [ThemeExtension].
@immutable
class KanbanStatusColors extends ThemeExtension<KanbanStatusColors> {
  const KanbanStatusColors({
    required this.newJob,
    required this.applied,
    required this.interview,
    required this.offer,
    required this.rejected,
  });

  /// Default dark theme instance mapping to [AppColors] tokens.
  static const dark = KanbanStatusColors(
    newJob: AppColors.kanbanNew,
    applied: AppColors.kanbanApplied,
    interview: AppColors.kanbanInterview,
    offer: AppColors.kanbanOffer,
    rejected: AppColors.kanbanRejected,
  );

  /// Color for newly discovered vacancy (Cyan `#38BDF8`).
  final Color newJob;

  /// Alias for [newJob] for status-named access.
  Color get newStatus => newJob;

  /// Alias for [newJob].
  Color get statusNew => newJob;

  /// Color for applied vacancy (Violet `#8B5CF6`).
  final Color applied;

  /// Color for interview stage (Amber `#F59E0B`).
  final Color interview;

  /// Color for job offer stage (Emerald `#10B981`).
  final Color offer;

  /// Color for rejected stage (Rose `#F43F5E`).
  final Color rejected;

  /// Returns the corresponding color for the given [JobStatus].
  Color colorFor(JobStatus status) {
    switch (status) {
      case JobStatus.newJob:
        return newJob;
      case JobStatus.applied:
        return applied;
      case JobStatus.interview:
        return interview;
      case JobStatus.offer:
        return offer;
      case JobStatus.rejected:
        return rejected;
    }
  }

  @override
  KanbanStatusColors copyWith({
    Color? newJob,
    Color? applied,
    Color? interview,
    Color? offer,
    Color? rejected,
  }) {
    return KanbanStatusColors(
      newJob: newJob ?? this.newJob,
      applied: applied ?? this.applied,
      interview: interview ?? this.interview,
      offer: offer ?? this.offer,
      rejected: rejected ?? this.rejected,
    );
  }

  @override
  KanbanStatusColors lerp(ThemeExtension<KanbanStatusColors>? other, double t) {
    if (other is! KanbanStatusColors) {
      return this;
    }
    return KanbanStatusColors(
      newJob: Color.lerp(newJob, other.newJob, t) ?? newJob,
      applied: Color.lerp(applied, other.applied, t) ?? applied,
      interview: Color.lerp(interview, other.interview, t) ?? interview,
      offer: Color.lerp(offer, other.offer, t) ?? offer,
      rejected: Color.lerp(rejected, other.rejected, t) ?? rejected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KanbanStatusColors &&
        other.newJob == newJob &&
        other.applied == applied &&
        other.interview == interview &&
        other.offer == offer &&
        other.rejected == rejected;
  }

  @override
  int get hashCode => Object.hash(newJob, applied, interview, offer, rejected);
}

/// Convenience getter on [BuildContext] to access Kanban status colors.
extension KanbanColorsExtension on BuildContext {
  KanbanStatusColors get kanbanColors =>
      Theme.of(this).extension<KanbanStatusColors>() ?? KanbanStatusColors.dark;
}
