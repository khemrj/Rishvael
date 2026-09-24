import 'package:flutter_application_1/core/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';



void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.7:8080',
  );

  const token = String.fromEnvironment(
    'ACCESS_TOKEN',
  );

  late ApiService api;

  setUp(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,

        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    api = ApiService(
      dio: dio,
    );
  });

  test(
    'POST /members creates a member profile',
    () async {
      final response =
          await api.post<Map<String, dynamic>>(
        '/api/v1/members',

        data: {
          'firstName': 'Khem',
          'lastName': 'Mercer',
          'headline':
              'Finance Analyst',
          'bio':
              'Finance professional focused on portfolio strategy.',
          'contactEmail':
              'alex.test@example.com',
          'phone':
              '+9779812345678',
          'yearsOfExperience': 4,
          'githubUrl':
              'https://github.com/alex',
          'linkedinUrl':
              'https://linkedin.com/in/alex',
          'websiteUrl':
              'https://example.com',
          'resumeUrl':
              'https://example.com/resume.pdf',
        },

        fromJson: (json) {
          return Map<String, dynamic>.from(
            json as Map,
          );
        },
      );

      expect(response, isNotEmpty);

      
    },
  );

}
// khem@gmail.com ko access token  :     eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiUk9MRV9DVVNUT01FUiIsInVzZXJJZCI6MzQsInVzZXJuYW1lIjoia2hlbUBnbWFpbC5jb20iLCJzdWIiOiJraGVtQGdtYWlsLmNvbSIsImlhdCI6MTc4OTkzMzUwNSwiZXhwIjoxNzkwMDE5OTA1fQ.zSM62MuGe0SkxUpb6NhxEwo43tY3DIDZQJtBzs96aJs