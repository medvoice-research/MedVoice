import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/auth/auth_user.dart';
import '../../domain/repositories/auth_repository/auth_repository.dart';
import '../network/constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  static final AuthRepositoryImpl _instance = AuthRepositoryImpl._internal();

  AuthRepositoryImpl._internal() : _client = http.Client();

  factory AuthRepositoryImpl() => _instance;

  // Injectable client for tests; defaults to the real http package.
  @visibleForTesting
  AuthRepositoryImpl.withClient(this._client);

  final http.Client _client;

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(Constants.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 401) {
        throw const AuthException('invalid_credentials');
      }
      if (response.statusCode != 200) {
        throw const AuthException('network_error');
      }
      return AuthResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } on AuthException {
      rethrow;
    } catch (_) {
      // Transport failure or an unexpected 200 body: same user-facing outcome.
      throw const AuthException('network_error');
    }
  }
}
