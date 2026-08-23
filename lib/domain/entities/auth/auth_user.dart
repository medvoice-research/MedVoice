class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: (json['full_name'] ?? '') as String,
        role: (json['role'] ?? 'physician') as String,
      );
}

class AuthException implements Exception {
  const AuthException(this.code);

  /// 'invalid_credentials' (401) or 'network_error' (unreachable / 5xx).
  final String code;

  String get message => code == 'invalid_credentials'
      ? 'Invalid email or password.'
      : 'Cannot reach server.';
}

class AuthResult {
  const AuthResult({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['access_token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
