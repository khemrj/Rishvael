import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_service.dart';
import '../models/opportunity_model.dart';

class OpportunityRepository {
  const OpportunityRepository(this._api);
  final ApiService _api;

  static const _basePath = '/api/v1/opportunities';

  Future<Opportunity> publish(OpportunityDraft draft) => _api.post<Opportunity>(
        _basePath,
        data: draft.toJson(),
        fromJson: (json) => Opportunity.fromJson(json as Map<String, dynamic>),
      );

  Future<Opportunity> saveDraft(OpportunityDraft draft) => _api.post<Opportunity>(
        '$_basePath/draft',
        data: draft.toJson(),
        fromJson: (json) => Opportunity.fromJson(json as Map<String, dynamic>),
      );

  Future<Opportunity> getById(String id) => _api.get<Opportunity>(
        '$_basePath/$id',
        fromJson: (json) => Opportunity.fromJson(json as Map<String, dynamic>),
      );

  Future<List<Opportunity>> list({Map<String, dynamic>? query}) => _api.get<List<Opportunity>>(
        _basePath,
        queryParameters: query,
        fromJson: (json) =>
            (json as List).map((e) => Opportunity.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<Opportunity> update(String id, OpportunityDraft draft) => _api.patch<Opportunity>(
        '$_basePath/$id',
        data: draft.toJson(),
        fromJson: (json) => Opportunity.fromJson(json as Map<String, dynamic>),
      );

  Future<void> delete(String id) => _api.deleteNoContent('$_basePath/$id');
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return OpportunityRepository(ref.watch(apiServiceProvider));
});