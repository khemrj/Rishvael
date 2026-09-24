import 'package:flutter_application_1/core/api_service.dart';
import 'package:flutter_application_1/models/member_setup_data.dart';

class MemberRepository {
  final ApiService _api;

  MemberRepository(this._api);

  Future<MemberSetupData> create(
    MemberSetupData data,
  ) {
    return _api.post<MemberSetupData>(
      '/api/v1/members',
      data: data.toJson(),
      fromJson: (json) {
        return MemberSetupData.fromJson(
          Map<String, dynamic>.from(
            json as Map,
          ),
        );
      },
    );
  }
}