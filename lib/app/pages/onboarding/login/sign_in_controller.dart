import 'package:flutter/material.dart';

import '../../../../common/base_controller.dart';
import '../../../../data/repository_impl/auth_repository_impl.dart';
import '../../../../domain/entities/auth/auth_user.dart';
import '../../../../domain/repositories/auth_repository/auth_repository.dart';

typedef String? Validator(String? value);

class SignInController extends BaseController {
  SignInController({AuthRepository? repository})
      : _repository = repository ?? AuthRepositoryImpl();

  final AuthRepository _repository;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Set when a login attempt fails; the view surfaces it and it is cleared on
  /// the next attempt. Stays null for local validation failures, which the
  /// Form already reports inline.
  String? errorMessage;

  @override
  void onResumed() {}

  @override
  void onListener() {}

  @override
  void firstLoad() {}

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    // Validate email format using regex
    if (!value.contains('@') &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null; // Return null if validation passes
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    // Add additional validation logic for password (e.g., minimum length, strength)
    return null; // Return null if validation passes
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  /// Returns true only when the credentials were accepted, so the view keeps
  /// ownership of navigation. Loading state rides on [showLoadingProgress] /
  /// [hideLoadingProgress], which flip `isLoading` and call `refreshUI()`.
  Future<bool> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    errorMessage = null;
    showLoadingProgress();
    try {
      await _repository.login(
          emailController.text.trim(), passwordController.text);
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      hideLoadingProgress();
    }
  }
}
