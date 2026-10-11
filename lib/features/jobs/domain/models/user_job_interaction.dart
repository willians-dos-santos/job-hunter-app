import 'package:flutter/foundation.dart';

import 'job_status.dart';

/// Represents a user mutation (status change, application timestamp, notes, archived)
/// for upserting into the `user_job_interactions` table.
@immutable
class UserJobInteraction {
  UserJobInteraction({
    required this.jobId,
    required this.status,
    this.notes,
    this.isArchived,
    DateTime? appliedAt,
  }) : appliedAt = (status == JobStatus.applied && appliedAt == null)
            ? DateTime.now()
            : appliedAt;

  /// Factory parser for interaction records.
  factory UserJobInteraction.fromJson(Map<String, dynamic> json) {
    final rawJobId = json['job_id'];
    final rawStatus = json['status'];
    final rawAppliedAt = json['applied_at'];
    final rawIsArchived = json['is_archived'];

    final status = JobStatus.fromString(rawStatus?.toString());
    final appliedAt = rawAppliedAt != null
        ? DateTime.tryParse(rawAppliedAt.toString())?.toLocal()
        : null;

    final isArchived = rawIsArchived != null
        ? (rawIsArchived == true ||
            rawIsArchived == 1 ||
            rawIsArchived.toString().toLowerCase() == 'true')
        : null;

    return UserJobInteraction(
      jobId: rawJobId?.toString() ?? '',
      status: status,
      notes: json['notes']?.toString(),
      isArchived: isArchived,
      appliedAt: appliedAt,
    );
  }

  /// Target vacancy identifier.
  final String jobId;

  /// Current user status in the funnel.
  final JobStatus status;

  /// User notes or interview logs.
  final String? notes;

  /// Whether the job was archived/discarded by the user.
  final bool? isArchived;

  /// Application timestamp (automatically populated if transitioning to `applied`).
  final DateTime? appliedAt;

  /// Converts this interaction entity into the exact payload for Supabase upsert.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'job_id': jobId,
      'status': status.value,
      'notes': notes,
      'applied_at': appliedAt?.toUtc().toIso8601String(),
    };
    if (isArchived != null) {
      data['is_archived'] = isArchived;
    }
    return data;
  }

  /// Returns a copy with the given fields replaced.
  UserJobInteraction copyWith({
    String? jobId,
    JobStatus? status,
    String? notes,
    bool? isArchived,
    DateTime? appliedAt,
  }) {
    return UserJobInteraction(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserJobInteraction &&
        other.jobId == jobId &&
        other.status == status &&
        other.notes == notes &&
        other.isArchived == isArchived &&
        other.appliedAt == appliedAt;
  }

  @override
  int get hashCode => Object.hash(jobId, status, notes, isArchived, appliedAt);

  @override
  String toString() {
    return 'UserJobInteraction(jobId: $jobId, status: ${status.value}, isArchived: $isArchived, appliedAt: $appliedAt)';
  }
}
