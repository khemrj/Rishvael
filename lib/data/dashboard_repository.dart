

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_failure.dart';
import '../models/user_profile.dart';
import '../models/opportunity_model.dart';
import '../models/feed_models.dart';

/// The repository is the ONLY place that knows JSON exists.
/// Above this line: models. Below: wire format. That seam is what lets you
/// swap REST for GraphQL, or add an offline cache, without touching a widget.
class DashboardRepository {
  DashboardRepository(this._client);

  // ignore: unused_field  (kept so the repo is constructed via a provider)
  final ApiClient _client;
  Dio get _dio => ApiClient.dio;

  /// Global validateStatus stays permissive so your existing pages keep
  /// working. New calls opt into strict 2xx here, so Dio throws on 4xx and
  /// `_guard` can turn it into a typed ApiFailure.
  static final Options _strict = ApiClient.strict;

  // --- reads ---------------------------------------------------------------

  Future<UserProfile> fetchProfile({CancelToken? cancel}) =>
      _get('/api/v1/me', cancel, (data) => UserProfile.fromJson(data as Map<String, dynamic>));

Future<List<T>> _getList<T>(
  String path,
  CancelToken? cancel,
  T Function(Map<String, dynamic>) fromJson, {
  Map<String, dynamic>? query,
}) async {
  final response = await _dio.get(path, queryParameters: query, cancelToken: cancel);
  final body = response.data;

  final List<dynamic> rawList = switch (body) {
    List() => body,
    {'data': List<dynamic>() && final data} => data, // your {success, message, data, timestamp} envelope
    _ => throw FormatException('Unexpected list shape for $path: ${body.runtimeType}'),
  };

  return rawList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
    Future<List<Opportunity>> fetchOpportunities({
    OpportunityKind? kind,
    String? query,
    CancelToken? cancel,
  }) =>
      _getList(
        '/api/v1/opportunities',
        cancel,
        Opportunity.fromJson,
        query: {
          if (kind != null) 'kind': kind.wire,
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );
  Future<List<ApplicationRecord>> fetchApplications({CancelToken? cancel}) =>
      _getList('/api/v1/me/applications', cancel, ApplicationRecord.fromJson);

  Future<List<AdvisorySession>> fetchAdvisory({CancelToken? cancel}) =>
      _getList('/api/v1/me/advisory-sessions', cancel, AdvisorySession.fromJson);

  Future<List<ConnectionSuggestion>> fetchSuggestions({CancelToken? cancel}) =>
      _getList('/api/v1/me/suggestions', cancel, ConnectionSuggestion.fromJson);

  // --- writes --------------------------------------------------------------

  Future<UserProfile> updateProfile(UserProfile profile) => _guard(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/api/v1/me',
          data: profile.toJson(),
          cancelToken: ApiClient.sessionToken,
          options: _strict,
        );
        return UserProfile.fromJson(res.data!);
      });

  Future<void> apply(String opportunityId, {String? note}) => _guard(() async {
        await _dio.post<void>(
          '/api/v1/opportunities/$opportunityId/applications',
          data: {'note': note},
          cancelToken: ApiClient.sessionToken,
          options: _strict,
        );
      });

  Future<String> uploadAvatar(String filePath) => _guard(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        });
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/v1/me/avatar',
          data: form,
          // Multipart: let it run long, and stream progress to the UI.
          options: _strict.copyWith(sendTimeout: const Duration(minutes: 2)),
        );
        return res.data!['avatarUrl'] as String;
      });

  // --- plumbing ------------------------------------------------------------

  /// Every network call goes through here so failures are typed exactly once.
  /// If you find yourself writing `try { } catch` in a widget, you skipped this.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<T> _get<T>(
    String path,
    CancelToken? cancel,
    T Function(Object? data) map,
  ) =>
      _guard(() async {
        final res = await _dio.get<Object?>(path,
            cancelToken: cancel, options: _strict);
        return map(res.data);
      });

  /// THE ISOLATE DECISION, in one method.
  ///
  /// The HTTP wait costs zero UI frames — it's `await`, the event loop is free.
  /// What DOES jank is mapping 2,000 JSON maps into 2,000 objects: that's
  /// synchronous CPU on the UI isolate, and at ~16ms/frame you drop frames.
  ///
  /// So: small list → map inline (spawning an isolate costs ~1–2ms + copy).
  ///     big list   → `Isolate.run`, which spawns, runs, returns, and dies.
  

  
}
