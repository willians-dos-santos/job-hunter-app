import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  FakePostgrestFilterBuilder({
    this.data,
    this.error,
    this.onEq,
    this.onOr,
    this.onOrder,
    this.onRange,
  });

  final T? data;
  final Object? error;
  final void Function(String column, Object value)? onEq;
  final void Function(String filters)? onOr;
  final void Function(String column, bool ascending)? onOrder;
  final void Function(int from, int to)? onRange;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    onEq?.call(column, value);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) {
    onOr?.call(filters);
    return this;
  }

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    onOrder?.call(column, ascending);
    return FakePostgrestTransformBuilder<T>(
      data: data,
      error: error,
      onRange: onRange,
    );
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    Map<String, dynamic>? singleData;
    if (data is List && (data as List).isNotEmpty) {
      singleData = (data as List).first as Map<String, dynamic>;
    } else if (data is Map<String, dynamic>) {
      singleData = data as Map<String, dynamic>;
    } else {
      singleData = null;
    }
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(
      data: singleData,
      error: error,
      onRange: onRange,
    );
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<T>.error(error!).then(onValue, onError: onError);
    }
    return Future<T>.value(data as T).then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder({
    this.data,
    this.error,
    this.onRange,
  });

  final T? data;
  final Object? error;
  final void Function(int from, int to)? onRange;

  @override
  PostgrestTransformBuilder<T> range(
    int from,
    int to, {
    String? referencedTable,
  }) {
    onRange?.call(from, to);
    return this;
  }

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<T>.error(error!).then(onValue, onError: onError);
    }
    return Future<T>.value(data as T).then(onValue, onError: onError);
  }
}
