import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/business.dart';

/// Thin wrapper around [ApiClient.dio] for the Business endpoints — the Dart
/// equivalent of what BusinessController + BusinessService do together, from
/// the client's point of view: typed methods in, a typed [Business] or a
/// typed failure out, Dio/HTTP details never leak past this class.
///
/// NOTE: this repo currently rethrows raw [DioException] on failure. Your
/// codebase already has a sealed `ApiFailure` hierarchy (used elsewhere) —
/// paste it and I'll replace the `rethrow`s below with the exact typed
/// mapping (409 duplicate email/registration number → your conflict
/// variant, 400 validation → your validation variant, etc.) instead of
/// guessing at constructor names that might not match.
class BusinessRepository {
  const BusinessRepository();

  static const _base = '/api/v1/businesses';

  Future<Business> register(BusinessRegistrationDraft draft) async {
    final res = await ApiClient.dio.post<Map<String, dynamic>>(
      '$_base/register',
      data: draft.toJson(),
      options: ApiClient.strict,
    );
    return Business.fromJson(res.data!);
  }

  /// The authenticated business's own profile — requires a ROLE_BUSINESS
  /// JWT, same as GET /businesses/me on the backend.
  Future<Business> getMyBusiness() async {
    final res = await ApiClient.dio.get<Map<String, dynamic>>(
      '$_base/me',
      options: ApiClient.strict,
    );
    return Business.fromJson(res.data!);
  }

  Future<Business> updateMyBusiness(BusinessUpdateDraft draft) async {
    final res = await ApiClient.dio.patch<Map<String, dynamic>>(
      '$_base/me',
      data: draft.toJson(),
      options: ApiClient.strict,
    );
    return Business.fromJson(res.data!);
  }

  /// Public — no auth required, matches GET /businesses/{id}.
  Future<Business> getBusinessById(int id) async {
    final res = await ApiClient.dio.get<Map<String, dynamic>>('$_base/$id');
    return Business.fromJson(res.data!);
  }
}