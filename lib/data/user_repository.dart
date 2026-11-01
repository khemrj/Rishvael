import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/data/user_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRepository {
  UserRepository(this._dio);
  final Dio _dio;

  Future<(List<UserDto>, bool)> searchUsersByUsername(String username, {int page = 0, int size = 10}) async {
  final response = await _dio.get('/api/v1/users/search', queryParameters: {
    'username': username,
    'page': page,
    'size': size,
  });

  final List<dynamic> content = response.data['content'] ?? [];
  final users = content.map((json) => UserDto.fromJson(json)).toList();
  final bool hasMore = response.data['hasNext'] ?? false;

  return (users, hasMore);
}
  }
  // ADD THIS PROVIDER BELOW YOUR REPOSITORY CLASS:
// -----------------------------------------------------------------

final userRepositoryProvider = Provider<UserRepository>((ref) {
  // Assumes you already have a dioProvider that supplies your configured Dio instance
  final dio = ref.watch(dioProvider); 
  return UserRepository(dio);
});
