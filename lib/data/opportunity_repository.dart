import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_failure.dart';
import '../models/opportunity_model.dart';

class OpportunityRepository {
  const OpportunityRepository();

  static const _basePath = '/api/v1/opportunities';

  Future<Opportunity> publish(OpportunityDraft draft) => _post(_basePath, draft);

  Future<Opportunity> saveDraft(OpportunityDraft draft) => _post('_basePath/draft', draft);

}Future<Opportunity> _post(String path, OpportunityDraft draft) async {
  try {
    final res = await ApiClient.dio.post<Map<String, dynamic>>(
      path,
      data: draft.toJson(),
      options: ApiClient.strict,
    );

    final body = res.data;
    if (body == null) {
      throw const ServerFailure('Empty response from server.');
    }

    // Backend wraps every response as { success, message, data, timestamp }.
    // The actual opportunity lives one level down in `data`.
    final success = body['success'] as bool? ?? false;
    if (!success) {
      throw UnknownFailure(body['message'] as String? ?? 'Request failed.');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ServerFailure('Server response was missing the expected data.');
    }

    return Opportunity.fromJson(data);
  } on DioException catch (e) {
    throw ApiFailure.from(e);
  }
}
final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return const OpportunityRepository();
});