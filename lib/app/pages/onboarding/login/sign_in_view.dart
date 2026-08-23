import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as clean;

import 'package:hexcolor/hexcolor.dart';
import 'package:med_voice/app/pages/onboarding/login/sign_in_controller.dart';
import 'package:med_voice/app/utils/module_utils.dart';
import 'package:med_voice/app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/base_controller.dart';
import '../../../../common/base_state_view.dart';

import '../../../utils/pages.dart';
import '../../../widgets/small_text_field.dart';
import '../signup/sign_up_view.dart';

class SignInView extends clean.View {
  const SignInView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SignInView();
  }
}

class _SignInView extends BaseStateView<SignInView, SignInController> {
  _SignInView() : super(SignInController());
  bool obscureText = true;

  @override
  bool isInitialAppbar() {
    return false;
  }

  @override
  String appBarTitle() {
    return "";
  }

  @override
  bool isHideBackButton() {
    return false;
  }

  @override
  Widget body(BuildContext context, BaseController controller) {
    SignInController _controller = controller as SignInController;
    final theme = Provider.of<ThemeProvider>(context).themeData;
    // const double defaultPadding = 16.0;
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: toSize(20)),
          child: Form(
            key: _controller.formKey,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(),
                  Text(
                    "Login",
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: toSize(50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: toSize(15),
                      // fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: toSize(5)),
                  SmallTextField(
                    fillColor: theme.colorScheme.onPrimary,
                    labelText: "EMAIL ADDRESS",
                    hint: "jiara@jiara.com",
                    validator: _controller.validateEmail,
                    showIconButton: false,
                    controller: _controller.emailController,
                  ),
                  SmallTextField(
                    fillColor: theme.colorScheme.onPrimary,
                    obscureText: obscureText,
                    hint: "Enter your password",
                    labelText: "PASSWORD",
                    iconButton: IconButton(
                      icon: Icon(
                        obscureText == true
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.colorScheme.onBackground,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                    showIconButton: true,
                    validator: _controller.validatePassword,
                    controller: _controller.passwordController,
                  ),
                  SizedBox(height: toSize(5)),
                  Padding(
                    padding: EdgeInsets.all(toSize(10)),
                    child: ElevatedButton(
                      onPressed: _controller.loadingState()
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              final ok = await _controller.submitForm();
                              if (!mounted) return;
                              if (ok) {
                                pushScreen(Pages.main, isAllowBack: false);
                              } else if (_controller.errorMessage != null) {
                                showErrorFromServer(_controller.errorMessage);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        fixedSize: Size(size.width * 0.76, toSize(50)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Log in",
                        style: TextStyle(
                          color: theme.colorScheme.surface,
                          fontSize: toSize(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: toSize(10)),
                  InkWell(
                    onTap: () {
                      pushScreen(Pages.reset);
                    },
                    child: Text("Forgot password?",
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                          fontSize: toSize(15),
                          // fontWeight: FontWeight.w300,
                        )),
                  ),
                  SizedBox(height: toSize(15)),
                  InkWell(
                    onTap: () {
                      pushScreen(Pages.signUp,
                          arguments: {isFromOnBoardingParam: false});
                    },
                    child: Text("Signup !",
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                          fontSize: toSize(14),
                          // fontWeight: FontWeight.w300,
                        )),
                  ),
                  Spacer(),
                ]),
          ),
        ));
  }
}
