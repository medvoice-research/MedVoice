import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:med_voice/app/widgets/theme.dart';
import 'package:med_voice/app/widgets/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../app/pages/onboarding/startup/startup_view.dart';
import '../app/utils/global.dart';
import '../data/network/constants.dart';
import 'dart:async';

import 'app_config.dart';

Future<Widget> initializeApp(AppConfig appConfig) async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initFirebase(appConfig);
  await getAppVersion();
  await getDeviceLang();
  return MyApp(appConfig);
}

class MyApp extends StatefulWidget {
  final AppConfig appConfig;

  MyApp(this.appConfig, {Key? key}) : super(key: key) {
    if (kDebugMode) debugPrint('BACKEND_ENDPOINT = ${Constants.baseUrl}');
    //set base url
    //Constants.baseUrl = appConfig.baseURL;
    //Global.mGoogleKey = appConfig.googleKey;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  Timer? _timer;
  @override
  didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("App is return");
        _startTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        debugPrint("App is pause");
        _stopTimer(); // Conservatively set a timer on all three
        break;
    }
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(minutes: 5), (timer) {});
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCare',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: StartupView(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

Future<void> getAppVersion() async {
  /// App version
  final info = await PackageInfo.fromPlatform();
  Global.appVersion = info.version;
}

/// Get device language to set for app language
Future<void> getDeviceLang() async {
  Global.mLang = window.locale.languageCode;
}
