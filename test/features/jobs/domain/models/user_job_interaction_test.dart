import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/models/user_job_interaction.dart';

void main() {
  group('UserJobInteraction', () {
    test('generates exact upsert keys in toJson()', () {
      final date = DateTime.utc(2026, 10, 10, 15, 30);
      final interaction = UserJobInteraction(
        jobId: 'job-55',
        status: JobStatus.interview,
        notes: 'Preparar case study de arquitetura',
        appliedAt: date,
      );

      final json = interaction.toJson();

      expect(json, {
        'job_id': 'job-55',
        'status': 'interview',
        'notes': 'Preparar case study de arquitetura',
        'applied_at': date.toIso8601String(),
      });
    });

    test('automatically sets appliedAt when status is applied and appliedAt is null', () {
      final interaction = UserJobInteraction(
        jobId: 'job-77',
        status: JobStatus.applied,
      );

      expect(interaction.appliedAt, isNotNull);
      expect(
        DateTime.now().difference(interaction.appliedAt!).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('preserves explicit appliedAt when provided for applied status', () {
      final customDate = DateTime.utc(2026, 9, 1);
      final interaction = UserJobInteraction(
        jobId: 'job-77',
        status: JobStatus.applied,
        appliedAt: customDate,
      );

      expect(interaction.appliedAt, customDate);
    });

    test('leaves appliedAt null when status is not applied', () {
      final interaction = UserJobInteraction(
        jobId: 'job-88',
        status: JobStatus.newJob,
      );

      expect(interaction.appliedAt, isNull);
    });

    test('correctly deserializes from json', () {
      final json = {
        'job_id': 'job-99',
        'status': 'offer',
        'notes': 'Proposta recebida!',
        'applied_at': '2026-10-01T10:00:00.000Z',
      };

      final interaction = UserJobInteraction.fromJson(json);

      expect(interaction.jobId, 'job-99');
      expect(interaction.status, JobStatus.offer);
      expect(interaction.notes, 'Proposta recebida!');
      expect(interaction.appliedAt, isNotNull);
    });

    test('supports copyWith, equality and hashCode', () {
      final date = DateTime.utc(2026, 10, 1);
      final a = UserJobInteraction(jobId: 'job-1', status: JobStatus.offer, appliedAt: date);
      final b = UserJobInteraction(jobId: 'job-1', status: JobStatus.offer, appliedAt: date);
      final c = a.copyWith(status: JobStatus.rejected);

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(c.status, JobStatus.rejected);
    });
  });
}
