import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as clean;
import 'package:hexcolor/hexcolor.dart';
import 'package:med_voice/app/pages/home/patient_doc/nurse_note/nurse_note_view.dart';
import 'package:med_voice/app/pages/home/user_profile/nurse_profile/nurse_profile_view.dart';
import 'package:provider/provider.dart';

import '../../../../common/base_controller.dart';
import '../../../../common/base_state_view.dart';
import '../../../utils/global.dart';
import '../../../widgets/theme_provider.dart';
import '../medical_archive/medical_archive_view.dart';
import '../recording/recording/recording_view.dart';
import '../recording/recording_android/recording_android_view.dart';
import 'main_controller.dart';

class MainView extends clean.View {
  const MainView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MainView();
  }
}

class _MainView extends BaseStateView<MainView, MainController> {
  _MainView() : super(MainController());

  MainController? mMainController;

  @override
  bool isInitialAppbar() {
    return false;
  }

  List<Widget>? tabs;

  onTapped(int index) {
    mMainController!.currentTabIndex = index;
    mMainController!.refreshUI();
  }

  @override
  void onStateCreated() {
    tabs = [
      // Adding your Views here, remember to position it the same as the index you assigned below
      const MedicalArchiveView(),
      (Platform.isIOS) ? RecordingView() : RecordingAndroidView(),
      NurseProfileView(),
    ];
  }

  @override
  void onStateDestroyed() {}

  @override
  String appBarTitle() {
    return "";
  }

  @override
  Widget body(BuildContext context, BaseController controller) {
    ThemeData theme = Provider.of<ThemeProvider>(context).themeData;
    return _body(controller, theme);
  }

  Widget _body(BaseController controller, ThemeData theme) {
    mMainController = controller as MainController;
    return Stack(children: [
      tabs![mMainController!.currentTabIndex],
      MediaQuery.of(context).orientation == Orientation.portrait
          ? Align(
              alignment: Alignment.bottomCenter,
              child: Theme(
                data: Theme.of(context).copyWith(
                    // sets the background color of the `BottomNavigationBar`
                    canvasColor: Colors.transparent,
                    // sets the active color of the `BottomNavigationBar` if `Brightness` is light
                    primaryColor: Colors.transparent),
                child: Container(
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                            //offset: Offset(0, 4),
                            color: Colors.black.withOpacity(0.1), //edited
                            spreadRadius: 2,
                            blurRadius: 11 //edited
                            )
                      ],
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24))),
                  // BottomNavigationBar pads itself by the home-indicator inset.
                  height: 82 + MediaQuery.viewPaddingOf(context).bottom,
                  child: BottomNavigationBar(
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    onTap: onTapped,
                    currentIndex: mMainController!.currentTabIndex,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    items: [
                      // Add _tab([index], [asset location], [title underneath the icon]
                      _tab(0, "assets/main_assets/ic_medical_archive",
                          "Archive", theme),
                      _tab(1, "assets/main_assets/ic_voice_recording", "Record",
                          theme),
                      _tab(2, "assets/main_assets/ic_nurse_profile", "Profile",
                          theme),
                    ],
                  ),
                ),
              ),
            )
          : Container(),
      //     : Container(),
    ]);
  }

  BottomNavigationBarItem _tab(
      int index, String? imageAsset, String namePage, ThemeData theme) {
    int badgeNumber = -1;
    if (index == 0 || index == 1 || index == 3 || index == 4) {
      badgeNumber = 0;
    } else {
      // Future implementation
    }
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageIcon(
                    imageAsset == "" ? null : AssetImage("${imageAsset!}.png"),
                    color: theme.colorScheme.secondary,
                    size: 18,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    namePage,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                    ),
                  )
                ],
              )),
          if (badgeNumber > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    badgeNumber > 9 ? "9+" : badgeNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
        ],
      ),
      activeIcon: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageIcon(
                    imageAsset == "" ? null : AssetImage("${imageAsset!}.png"),
                    color: theme.colorScheme.onSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    namePage,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: theme.colorScheme.onSecondary,
                    ),
                  )
                ],
              )),
          if (badgeNumber > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    badgeNumber > 9 ? "9+" : badgeNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
        ],
      ),
      label: "",
    );
  }
}
