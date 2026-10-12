import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config_category.dart';

void main() {
  group('SearchConfigCategory', () {
    test('correctly parses valid categories', () {
      expect(SearchConfigCategory.fromString('keyword'), SearchConfigCategory.keyword);
      expect(SearchConfigCategory.fromString('excluded'), SearchConfigCategory.excluded);
      expect(SearchConfigCategory.fromString('excluded_keyword'), SearchConfigCategory.excludedKeyword);
      expect(SearchConfigCategory.fromString('ats_filter'), SearchConfigCategory.atsFilter);
      expect(SearchConfigCategory.fromString('location'), SearchConfigCategory.location);
      expect(SearchConfigCategory.fromString('company'), SearchConfigCategory.company);
    });

    test('case insensitive parsing and trimming', () {
      expect(SearchConfigCategory.fromString(' KEYWORD '), SearchConfigCategory.keyword);
      expect(SearchConfigCategory.fromString('Excluded'), SearchConfigCategory.excluded);
    });

    test('gracefully falls back to keyword for null or unknown strings', () {
      expect(SearchConfigCategory.fromString(null), SearchConfigCategory.keyword);
      expect(SearchConfigCategory.fromString('unknown_category'), SearchConfigCategory.keyword);
    });
  });

  group('SearchConfig Model & DTO', () {
    test('correctly parses JSON payload', () {
      final json = <String, dynamic>{
        'id': 'cfg-1',
        'category': 'location',
        'value': 'Remoto',
        'is_active': true,
      };

      final config = SearchConfig.fromJson(json);

      expect(config.id, 'cfg-1');
      expect(config.category, SearchConfigCategory.location);
      expect(config.value, 'Remoto');
      expect(config.isActive, isTrue);
    });

    test('handles numeric id defensively and defaults isActive to true if null', () {
      final json = <String, dynamic>{
        'id': 42,
        'category': 'keyword',
        'value': 'Flutter',
      };

      final config = SearchConfig.fromJson(json);

      expect(config.id, '42');
      expect(config.isActive, isTrue);
    });

    test('toJson generates expected map for Supabase', () {
      const config = SearchConfig(
        id: 'cfg-2',
        category: SearchConfigCategory.excluded,
        value: 'Presencial',
        isActive: false,
      );

      final json = config.toJson();

      expect(json, {
        'id': 'cfg-2',
        'category': 'excluded_keyword',
        'value': 'Presencial',
        'is_active': false,
      });
    });

    test('supports copyWith, equality and hashCode', () {
      const a = SearchConfig(
        id: '1',
        category: SearchConfigCategory.company,
        value: 'Google',
        isActive: true,
      );
      const b = SearchConfig(
        id: '1',
        category: SearchConfigCategory.company,
        value: 'Google',
        isActive: true,
      );
      final c = a.copyWith(isActive: false);

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(c.isActive, isFalse);
    });
  });
}
