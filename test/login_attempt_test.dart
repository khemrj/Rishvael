import 'package:flutter_application_1/core/api_service.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  const email = String.fromEnvironment(
    'LOGIN_EMAIL',
  );

  const password = String.fromEnvironment(
    'LOGIN_PASSWORD',
  );

  test(
    'POST /api/v1/auth/login - login successfully',
    () async {
      // Make sure credentials were supplied.
      expect(
        email,
        isNotEmpty,
        reason:
            'LOGIN_EMAIL was not provided.',
      );

      expect(
        password,
        isNotEmpty,
        reason:
            'LOGIN_PASSWORD was not provided.',
      );

      final api = ApiService();

      final response =
          await api.post<Map<String, dynamic>>(
        '/api/v1/auth/login',

        data: {
          'email': email,
          'password': password,
        },

        fromJson: (json) {
          return Map<String, dynamic>.from(
            json as Map,
          );
        },
      );

      // ------------------------------------------------------
      // BASIC ASSERTIONS
      // ------------------------------------------------------

      expect(response, isNotEmpty);

      expect(
        response['token'],
        isA<String>(),
      );

      expect(
        response['tokenType'],
        'Bearer',
      );

      expect(
        response['email'],
        email,
      );

      expect(
        response['userId'],
        isA<num>(),
      );

      expect(
        response['role'],
        isA<String>(),
      );

      // ------------------------------------------------------
      // DISPLAY ACCESS TOKEN
      // ------------------------------------------------------

      print('');
      print('==============================================');
      print('             LOGIN TEST SUCCESS');
      print('==============================================');
      print('User ID   : ${response['userId']}');
      print('Email     : ${response['email']}');
      print('Role      : ${response['role']}');
      print('TokenType : ${response['tokenType']}');
      print('Expires   : ${response['expiresIn']} ms');
      print('');
      print('ACCESS TOKEN:');
      print(response['token']);
      print('==============================================');
      print('');
    },
  );
}


//flutter test test/login_attempt_test.dart  --dart-define=LOGIN_EMAIL=khem@gmail.com --dart-define=LOGIN_PASSWORD=Sometimes@123 --dart-define=API_BASE_URL=http:\\192.168.1.7:8080