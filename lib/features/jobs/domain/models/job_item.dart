import 'package:flutter/foundation.dart';

import 'job_status.dart';

/// Represents an enriched job listing viewed by the user from `v_user_jobs`.
@immutable
class JobItem {
  const JobItem({
    required this.jobId,
    required this.title,
    required this.companyName,
    required this.platform,
    required this.jobUrl,
    required this.status,
    this.userId,
    this.createdAt,
    this.location,
    this.salaryText,
    this.notes,
    this.appliedAt,
    this.publishedAt,
    this.isArchived = false,
  });

  /// Factory parser for payloads originating from the `v_user_jobs` view.
  ///
  /// Resiliently handles missing, unexpected, and alternative column names
  /// (such as `company`, `ats`, `url`, `job_created_at`).
  factory JobItem.fromJson(Map<String, dynamic> json) {
    final rawJobId = json['job_id'];
    final rawTitle = json['title'];
    final rawCompany = json['company_name'] ?? json['company'];
    final rawPlatform = json['platform'] ?? json['ats'];
    final rawUrl = json['job_url'] ?? json['url'];
    final rawCreatedAt = json['created_at'] ?? json['job_created_at'];
    final rawAppliedAt = json['applied_at'];
    final rawPublishedAt = json['published_at'];
    final rawIsArchived = json['is_archived'];
    final rawUserId = json['user_id'];

    final createdAtParsed = rawCreatedAt != null
        ? DateTime.tryParse(rawCreatedAt.toString())?.toLocal()
        : null;

    final appliedAtParsed = rawAppliedAt != null
        ? DateTime.tryParse(rawAppliedAt.toString())?.toLocal()
        : null;

    final publishedAtParsed = rawPublishedAt != null
        ? DateTime.tryParse(rawPublishedAt.toString())?.toLocal()
        : null;

    final isArchivedParsed = rawIsArchived == true ||
        rawIsArchived == 1 ||
        rawIsArchived.toString().toLowerCase() == 'true';

    return JobItem(
      jobId: rawJobId?.toString() ?? '',
      userId: rawUserId?.toString(),
      title: rawTitle?.toString() ?? '',
      companyName: rawCompany?.toString() ?? '',
      platform: rawPlatform?.toString() ?? '',
      jobUrl: rawUrl?.toString() ?? '',
      location: json['location']?.toString(),
      salaryText: json['salary_text']?.toString(),
      status: JobStatus.fromString(json['status']?.toString()),
      notes: json['notes']?.toString(),
      appliedAt: appliedAtParsed,
      publishedAt: publishedAtParsed,
      createdAt: createdAtParsed ?? publishedAtParsed,
      isArchived: isArchivedParsed,
    );
  }

  /// Unique identifier of the job (int or string cast to String).
  final String jobId;

  /// User identifier owning interaction with this job (optional, null if unclaimed).
  final String? userId;

  /// Job role title.
  final String title;

  /// Hiring company name.
  final String companyName;

  /// Platform where the vacancy was scraped (e.g. LinkedIn, Gupy, Catho).
  final String platform;

  /// Direct URL to the job posting.
  final String jobUrl;

  /// Geographic or remote work location (optional).
  final String? location;

  /// Formatted compensation or salary range string (optional).
  final String? salaryText;

  /// Current funnel status in the Kanban board.
  final JobStatus status;

  /// User personal notes, tips or interview feedback (optional).
  final String? notes;

  /// Timestamp when application was submitted (optional).
  final DateTime? appliedAt;

  /// Timestamp when job was published (optional).
  final DateTime? publishedAt;

  /// Timestamp when vacancy was ingested (optional, falls back to publishedAt).
  final DateTime? createdAt;

  /// Whether the job has been archived/discarded by the user.
  final bool isArchived;

  // --- Display Helpers ---

  /// User-friendly formatted salary text with fallback.
  String get displaySalary {
    if (salaryText != null && salaryText!.trim().isNotEmpty) {
      return salaryText!.trim();
    }
    return 'Não informado';
  }

  /// User-friendly location with fallback.
  String get displayLocation {
    if (location != null && location!.trim().isNotEmpty) {
      return location!.trim();
    }
    return 'Não informado';
  }

  /// User-friendly notes with fallback.
  String get displayNotes {
    if (notes != null && notes!.trim().isNotEmpty) {
      return notes!.trim();
    }
    return 'Sem anotações';
  }

  /// Effective date for ordering (prefers publishedAt, falls back to createdAt).
  DateTime? get effectiveDate => publishedAt ?? createdAt;

  /// Whether the job has been submitted/applied.
  bool get isApplied => status != JobStatus.newJob;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'job_id': jobId,
      if (userId != null && userId!.trim().isNotEmpty) 'user_id': userId!.trim(),
      'title': title,
      'company_name': companyName,
      'platform': platform,
      'job_url': jobUrl,
      'location': location,
      'salary_text': salaryText,
      'status': status.value,
      'notes': notes,
      'applied_at': appliedAt?.toUtc().toIso8601String(),
      'published_at': publishedAt?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'is_archived': isArchived,
    };
  }

  /// Returns a copy of this [JobItem] with the given fields replaced.
  JobItem copyWith({
    String? jobId,
    String? userId,
    String? title,
    String? companyName,
    String? platform,
    String? jobUrl,
    String? location,
    String? salaryText,
    JobStatus? status,
    String? notes,
    DateTime? appliedAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return JobItem(
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      platform: platform ?? this.platform,
      jobUrl: jobUrl ?? this.jobUrl,
      location: location ?? this.location,
      salaryText: salaryText ?? this.salaryText,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      appliedAt: appliedAt ?? this.appliedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobItem &&
        other.jobId == jobId &&
        other.userId == userId &&
        other.title == title &&
        other.companyName == companyName &&
        other.platform == platform &&
        other.jobUrl == jobUrl &&
        other.location == location &&
        other.salaryText == salaryText &&
        other.status == status &&
        other.notes == notes &&
        other.appliedAt == appliedAt &&
        other.publishedAt == publishedAt &&
        other.createdAt == createdAt &&
        other.isArchived == isArchived;
  }

  @override
  int get hashCode => Object.hash(
        jobId,
        userId,
        title,
        companyName,
        platform,
        jobUrl,
        location,
        salaryText,
        status,
        notes,
        appliedAt,
        publishedAt,
        createdAt,
        isArchived,
      );

  @override
  String toString() {
    return 'JobItem(jobId: $jobId, userId: $userId, title: $title, company: $companyName, status: ${status.value}, isArchived: $isArchived)';
  }
}
