import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';

void main() {
  group('JobItem.fromJson & Serialization', () {
    final fullJson = <String, dynamic>{
      'job_id': 'job-101',
      'title': 'Senior Flutter Engineer',
      'company_name': 'Acme Tech Solutions',
      'platform': 'LinkedIn',
      'job_url': 'https://linkedin.com/jobs/view/101',
      'location': 'Remoto - Brasil',
      'salary_text': 'R\$ 15.000 - R\$ 18.000',
      'status': 'interview',
      'notes': 'Primeira entrevista técnica realizada com sucesso.',
      'applied_at': '2026-10-05T14:30:00.000Z',
      'created_at': '2026-10-01T09:00:00.000Z',
    };

    test('correctly parses full JSON payload from v_user_jobs', () {
      final item = JobItem.fromJson(fullJson);

      expect(item.jobId, 'job-101');
      expect(item.title, 'Senior Flutter Engineer');
      expect(item.companyName, 'Acme Tech Solutions');
      expect(item.platform, 'LinkedIn');
      expect(item.jobUrl, 'https://linkedin.com/jobs/view/101');
      expect(item.location, 'Remoto - Brasil');
      expect(item.salaryText, 'R\$ 15.000 - R\$ 18.000');
      expect(item.status, JobStatus.interview);
      expect(item.notes, 'Primeira entrevista técnica realizada com sucesso.');
      expect(item.appliedAt, isNotNull);
      expect(item.createdAt, isNotNull);
      expect(item.isApplied, isTrue);
    });

    test('handles numeric job_id defensively', () {
      final json = <String, dynamic>{
        ...fullJson,
        'job_id': 9999,
      };

      final item = JobItem.fromJson(json);
      expect(item.jobId, '9999');
    });

    test('correctly parses id column as jobId when job_id is missing', () {
      final json = <String, dynamic>{
        'id': 'solides_12345',
        'title': 'Engenheiro de Software',
        'company': 'Tech Corp',
        'ats': 'solides',
        'url': 'https://vagas.solides.com.br/12345',
      };

      final item = JobItem.fromJson(json);
      expect(item.jobId, 'solides_12345');
      expect(item.title, 'Engenheiro de Software');
      expect(item.companyName, 'Tech Corp');
      expect(item.platform, 'solides');
      expect(item.jobUrl, 'https://vagas.solides.com.br/12345');
    });

    test('gracefully handles null optional fields and provides display fallbacks', () {
      final minimalJson = <String, dynamic>{
        'job_id': 'job-102',
        'title': 'Flutter Developer',
        'company_name': 'Startup Labs',
        'platform': 'Gupy',
        'job_url': 'https://gupy.io/job/102',
        'location': null,
        'salary_text': null,
        'status': 'new',
        'notes': null,
        'applied_at': null,
        'created_at': '2026-10-10T12:00:00.000Z',
      };

      final item = JobItem.fromJson(minimalJson);

      expect(item.location, isNull);
      expect(item.salaryText, isNull);
      expect(item.notes, isNull);
      expect(item.appliedAt, isNull);
      expect(item.status, JobStatus.newJob);
      expect(item.isApplied, isFalse);

      // Display fallbacks
      expect(item.displaySalary, 'Não informado');
      expect(item.displayLocation, 'Não informado');
      expect(item.displayNotes, 'Sem anotações');
    });

    test('falls back gracefully to JobStatus.newJob on unknown status values', () {
      final json = <String, dynamic>{
        ...fullJson,
        'status': 'unexpected_future_stage',
      };

      final item = JobItem.fromJson(json);
      expect(item.status, JobStatus.newJob);
    });

    test('toJson generates exact schema matching backend expectations', () {
      final item = JobItem.fromJson(fullJson);
      final json = item.toJson();

      expect(json['job_id'], 'job-101');
      expect(json['title'], 'Senior Flutter Engineer');
      expect(json['company_name'], 'Acme Tech Solutions');
      expect(json['platform'], 'LinkedIn');
      expect(json['job_url'], 'https://linkedin.com/jobs/view/101');
      expect(json['location'], 'Remoto - Brasil');
      expect(json['salary_text'], 'R\$ 15.000 - R\$ 18.000');
      expect(json['status'], 'interviewing');
      expect(json['notes'], 'Primeira entrevista técnica realizada com sucesso.');
      expect(json['applied_at'], contains('2026-10-05T14:30:00'));
      expect(json['created_at'], contains('2026-10-01T09:00:00'));
    });

    test('correctly parses published_at, is_archived and resolves effectiveDate', () {
      final json = <String, dynamic>{
        ...fullJson,
        'published_at': '2026-10-02T10:00:00.000Z',
        'is_archived': true,
      };

      final item = JobItem.fromJson(json);

      expect(item.publishedAt, isNotNull);
      expect(item.isArchived, isTrue);
      expect(item.effectiveDate, item.publishedAt);
    });

    test('correctly parses status: archived as isArchived = true', () {
      final json = <String, dynamic>{
        ...fullJson,
        'status': 'archived',
      };

      final item = JobItem.fromJson(json);

      expect(item.isArchived, isTrue);
    });

    test('falls back to published_at when created_at is absent from view payload', () {
      final payloadWithoutCreatedAt = <String, dynamic>{
        'job_id': 'job-200',
        'title': 'Flutter Lead',
        'company_name': 'Remote Inc',
        'platform': 'LinkedIn',
        'job_url': 'https://example.com/200',
        'status': 'new',
        'published_at': '2026-10-11T12:00:00.000Z',
      };

      final item = JobItem.fromJson(payloadWithoutCreatedAt);

      expect(item.publishedAt, isNotNull);
      expect(item.createdAt, equals(item.publishedAt));
      expect(item.effectiveDate, equals(item.publishedAt));
    });

    test('handles absence of both created_at and published_at gracefully', () {
      final payloadWithoutDates = <String, dynamic>{
        'job_id': 'job-201',
        'title': 'Flutter Lead',
        'company_name': 'Remote Inc',
        'platform': 'LinkedIn',
        'job_url': 'https://example.com/201',
        'status': 'new',
      };

      final item = JobItem.fromJson(payloadWithoutDates);

      expect(item.publishedAt, isNull);
      expect(item.createdAt, isNull);
      expect(item.effectiveDate, isNull);
    });

    test('correctly parses real Supabase v_user_jobs schema columns with aliases', () {
      final realViewJson = <String, dynamic>{
        'job_id': 'gupy:12676866',
        'ats': 'gupy',
        'external_id': '12676866',
        'title': 'Analista de Dados e BI Pleno',
        'company': 'Looqbox',
        'location': 'Remoto',
        'url': 'https://looqbox.gupy.io/job/123',
        'published_at': '2026-10-05T15:00:59.622+00:00',
        'job_created_at': '2026-10-06T09:05:37.535993+00:00',
        'status': 'new',
        'notes': null,
        'applied_at': null,
        'user_id': null,
      };

      final item = JobItem.fromJson(realViewJson);

      expect(item.jobId, 'gupy:12676866');
      expect(item.title, 'Analista de Dados e BI Pleno');
      expect(item.companyName, 'Looqbox');
      expect(item.platform, 'gupy');
      expect(item.jobUrl, 'https://looqbox.gupy.io/job/123');
      expect(item.location, 'Remoto');
      expect(item.publishedAt, isNotNull);
      expect(item.createdAt, isNotNull);
      expect(item.status, JobStatus.newJob);
      expect(item.userId, isNull);
    });

    test('supports copyWith, equality and hashCode', () {
      final original = JobItem.fromJson(fullJson);
      final cloned = JobItem.fromJson(fullJson);
      final modified = original.copyWith(status: JobStatus.offer);

      expect(original == cloned, isTrue);
      expect(original.hashCode, cloned.hashCode);
      expect(original == modified, isFalse);
      expect(modified.status, JobStatus.offer);
    });

    test('correctly parses pipeline_status when status key is absent', () {
      final jsonWithPipelineStatus = <String, dynamic>{
        'job_id': 'job-303',
        'title': 'Senior Dart Developer',
        'company_name': 'Dart Corp',
        'platform': 'LinkedIn',
        'job_url': 'https://example.com/303',
        'pipeline_status': 'interviewing',
      };

      final item = JobItem.fromJson(jsonWithPipelineStatus);

      expect(item.jobId, 'job-303');
      expect(item.status, JobStatus.interview);
    });
  });
}
