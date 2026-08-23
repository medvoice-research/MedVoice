import '../../entities/auth/auth_user.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
}
