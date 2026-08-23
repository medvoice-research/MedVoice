import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/pages/onboarding/login/sign_in_controller.dart';
import 'package:med_voice/domain/entities/auth/auth_user.dart';
import 'package:med_voice/domain/repositories/auth_repository/auth_repository.dart';

void main() {
  // submitForm() needs a live FormState, so the fields are pumped for real.
  Future<SignInController> pumpLoginForm(
    WidgetTester tester,
    AuthRepository repository, {
    String email = 'doctor@medvoice.local',
    String password = 'MedVoice2026!',
  }) async {
    final controller = SignInController(repository: repository);
    controller.emailController.text = email;
    controller.passwordController.text = password;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: controller.formKey,
          child: ListView(children: [
            TextFormField(
              controller: controller.emailController,
              validator: controller.validateEmail,
            ),
            TextFormField(
              controller: controller.passwordController,
              validator: controller.validatePassword,
            ),
          ]),
        ),
      ),
    ));
    return controller;
  }

  testWidgets('returns true and leaves no error after a successful login',
      (tester) async {
    final controller = await pumpLoginForm(tester, _StubAuthRepository());

    final ok = await controller.submitForm();

    expect(ok, isTrue);
    expect(controller.errorMessage, isNull);
    expect(controller.loadingState(), isFalse);
  });

  testWidgets('trims the email before calling the repository', (tester) async {
    final repository = _StubAuthRepository();
    final controller = await pumpLoginForm(tester, repository,
        email: '  doctor@medvoice.local  ');

    await controller.submitForm();

    expect(repository.lastEmail, 'doctor@medvoice.local');
    expect(repository.lastPassword, 'MedVoice2026!');
  });

  testWidgets('surfaces the 401 message and returns false', (tester) async {
    final controller = await pumpLoginForm(
        tester, _StubAuthRepository(error: const AuthException('invalid_credentials')));

    final ok = await controller.submitForm();

    expect(ok, isFalse);
    expect(controller.errorMessage, 'Invalid email or password.');
    expect(controller.loadingState(), isFalse);
  });

  testWidgets('surfaces the network message and returns false', (tester) async {
    final controller = await pumpLoginForm(
        tester, _StubAuthRepository(error: const AuthException('network_error')));

    final ok = await controller.submitForm();

    expect(ok, isFalse);
    expect(controller.errorMessage, 'Cannot reach server.');
  });

  testWidgets('clears a stale error on the next attempt', (tester) async {
    final repository =
        _StubAuthRepository(error: const AuthException('network_error'));
    final controller = await pumpLoginForm(tester, repository);

    await controller.submitForm();
    expect(controller.errorMessage, 'Cannot reach server.');

    repository.error = null;
    final ok = await controller.submitForm();

    expect(ok, isTrue);
    expect(controller.errorMessage, isNull);
  });

  testWidgets('is loading while the request is in flight', (tester) async {
    final repository = _StubAuthRepository()..gate = Completer<void>();
    final controller = await pumpLoginForm(tester, repository);

    final pending = controller.submitForm();
    expect(controller.loadingState(), isTrue);

    repository.gate!.complete();
    await pending;
    expect(controller.loadingState(), isFalse);
  });

  testWidgets('does not call the repository when validation fails',
      (tester) async {
    final repository = _StubAuthRepository();
    final controller = await pumpLoginForm(tester, repository, email: '');

    final ok = await controller.submitForm();

    expect(ok, isFalse);
    expect(repository.callCount, 0);
    // Inline field errors already explain it, so no snackbar message is set.
    expect(controller.errorMessage, isNull);
  });
}

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.error});

  AuthException? error;
  String? lastEmail;
  String? lastPassword;
  int callCount = 0;

  /// When set, login blocks until the test completes it.
  Completer<void>? gate;

  @override
  Future<AuthResult> login(String email, String password) async {
    callCount++;
    lastEmail = email;
    lastPassword = password;
    if (gate != null) {
      await gate!.future;
    }
    if (error != null) {
      throw error!;
    }
    return const AuthResult(
      accessToken: 'jwt123',
      user: AuthUser(
        id: 1,
        email: 'doctor@medvoice.local',
        fullName: 'Dr. Demo',
        role: 'physician',
      ),
    );
  }
}
