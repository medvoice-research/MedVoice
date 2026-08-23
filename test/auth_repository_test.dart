import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:med_voice/data/network/constants.dart';
import 'package:med_voice/data/repository_impl/auth_repository_impl.dart';
import 'package:med_voice/domain/entities/auth/auth_user.dart';

void main() {
  Constants.baseUrl = 'http://test.local:8000/';

  group('AuthRepositoryImpl.login', () {
    test('posts JSON credentials and parses token and user on 200', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/login');
        expect(request.headers['content-type'], contains('application/json'));
        expect(jsonDecode(request.body), {
          'email': 'doctor@medvoice.local',
          'password': 'pw',
        });
        return http.Response(
          '{"access_token":"jwt123","token_type":"bearer","user":'
          '{"id":1,"email":"doctor@medvoice.local","full_name":"Dr. Demo","role":"physician"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = AuthRepositoryImpl.withClient(mock);

      final result = await repo.login('doctor@medvoice.local', 'pw');

      expect(result.accessToken, 'jwt123');
      expect(result.user.id, 1);
      expect(result.user.email, 'doctor@medvoice.local');
      expect(result.user.fullName, 'Dr. Demo');
      expect(result.user.role, 'physician');
    });

    test('throws invalid_credentials on 401', () async {
      final mock = MockClient((request) async => http.Response(
            '{"detail":"Invalid email or password","error_code":"invalid_credentials"}',
            401,
            headers: {'content-type': 'application/json'},
          ));
      final repo = AuthRepositoryImpl.withClient(mock);

      await expectLater(
        repo.login('doctor@medvoice.local', 'bad'),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'code', 'invalid_credentials')
            .having((e) => e.message, 'message', 'Invalid email or password.')),
      );
    });

    test('throws network_error on server error', () async {
      final mock =
          MockClient((request) async => http.Response('{"detail": "boom"}', 500));
      final repo = AuthRepositoryImpl.withClient(mock);

      await expectLater(
        repo.login('a@b.co', 'pw'),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'code', 'network_error')
            .having((e) => e.message, 'message', 'Cannot reach server.')),
      );
    });

    test('throws network_error when the request fails outright', () async {
      final mock = MockClient((request) async => throw http.ClientException('down'));
      final repo = AuthRepositoryImpl.withClient(mock);

      await expectLater(
        repo.login('a@b.co', 'pw'),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'code', 'network_error')),
      );
    });

    test('throws network_error on a 200 with an unexpected body shape', () async {
      final mock = MockClient((request) async => http.Response(
            '{"token":"nope"}',
            200,
            headers: {'content-type': 'application/json'},
          ));
      final repo = AuthRepositoryImpl.withClient(mock);

      await expectLater(
        repo.login('a@b.co', 'pw'),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'code', 'network_error')),
      );
    });
  });
}
