import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as clean;
import 'package:hexcolor/hexcolor.dart';
import 'package:med_voice/app/pages/home/recording/recording_android/recording_android_controller.dart';
import 'package:med_voice/app/utils/module_utils.dart';
import 'package:med_voice/data/repository_impl/audio_repository_impl.dart';
import 'package:provider/provider.dart';

import '../../../../../common/base_controller.dart';
import '../../../../../common/base_state_view.dart';
import '../../../../utils/global.dart';
import '../../../../widgets/theme_provider.dart';
import '../../../../../domain/entities/recording/recording_detail.dart';
import '../../../../widgets/recording_result_view.dart';

class RecordingAndroidView extends clean.View {
  const RecordingAndroidView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RecordingAndroidView();
  }
}

class _RecordingAndroidView
    extends BaseStateView<RecordingAndroidView, RecordingAndroidController> {
  _RecordingAndroidView()
      : super(RecordingAndroidController(AudioRepositoryImpl()));

  RecordingAndroidController? recordingAndroidController;

  @override
  bool isInitialAppbar() {
    return true;
  }

  @override
  String appBarTitle() {
    return "Android Recorder";
  }

  @override
  bool isHideBackButton() {
    return true;
  }

  @override
  void onStateDestroyed() {
    recordingAndroidController?.recordSub?.cancel();
    recordingAndroidController?.amplitudeSub?.cancel();
    recordingAndroidController?.audioRecorder.dispose();
    recordingAndroidController?.speechServiceController?.stop();
    recordingAndroidController?.speechServiceController?.reset();
    recordingAndroidController?.speechServiceController?.dispose();
    super.onStateDestroyed();
  }

  @override
  Widget body(BuildContext context, BaseController controller) {
    recordingAndroidController = controller as RecordingAndroidController;
    ThemeData theme = Provider.of<ThemeProvider>(context).themeData;

    final RecordingDetail? result = recordingAndroidController!.uploadResult;
    if (result != null) return _resultBody(context, result);

    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: toSize(20)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            SizedBox(height: toSize(10)),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: toSize(20), vertical: 20),
                child: Container(
                    height: toSize(400),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: toSize(15), vertical: toSize(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        (recordingAndroidController!.speechServiceController !=
                                null)
                            ? StreamBuilder(
                                stream: recordingAndroidController!
                                    .speechServiceController!
                                    .onPartial(),
                                builder: (context, snapshot) => Text((snapshot
                                                .data !=
                                            null &&
                                        snapshot.data!.isNotEmpty)
                                    ? "Predictions: ${recordingAndroidController!.decodePartialTranscript(snapshot.data.toString())}"
                                    : "Predictions: ${recordingAndroidController!.guideText}."))
                            : const SizedBox(),
                        const Spacer(),
                        Divider(color: Colors.black.withOpacity(0.2)),
                        (recordingAndroidController!.speechServiceController !=
                                null)
                            ? StreamBuilder(
                                stream: recordingAndroidController!
                                    .speechServiceController!
                                    .onResult(),
                                builder: (context, snapshot) => Text(
                                    "Result: ${(snapshot.data != null && snapshot.data!.isNotEmpty) ? recordingAndroidController!.decodeCompleteTranscript(snapshot.data.toString()) : "Will be filtered from prediction texts."}"))
                            : const SizedBox(),
                        const Spacer(),
                      ],
                    )),
              ),
            ),
            recordingAndroidController!.speechEnabled
                ? _buildTimer(theme)
                : SizedBox(height: toSize(25)),
            SizedBox(height: toSize(10)),
            const Text('Upload language'),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'vi', label: Text('Tiếng Việt')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {recordingAndroidController!.uploadLanguage},
              onSelectionChanged: recordingAndroidController!.speechEnabled || recordingAndroidController!.isStartingRecording
                  ? null
                  : (s) =>
                      recordingAndroidController!.setUploadLanguage(s.first),
            ),
            const Text('Live preview uses English only'),
            Padding(
              // ponytail: keep the mic clear of the overlaid 82px bottom bar.
              padding: EdgeInsets.only(bottom: 82, top: toSize(20)),
              child: AvatarGlow(
                animate: recordingAndroidController!.speechEnabled ? true : false,
                glowColor: theme.colorScheme.primary,
                glowRadiusFactor: 0.3,
                duration: const Duration(milliseconds: 1700),
                repeat: true,
                child: InkWell(
                    onTap: () {
                      if (!recordingAndroidController!.speechEnabled) {
                        recordingAndroidController!.startListening();
                      } else {
                        recordingAndroidController!.stopListening();
                      }
                    },
                    child: Container(
                        height: toSize(80),
                        width: toSize(80),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(50)),
                        child: Icon(
                            recordingAndroidController!.speechEnabled
                                ? Icons.mic
                                : Icons.mic_off,
                            size: toSize(35),
                            color: HexColor(
                                Global.mColors['white_2'].toString())))),
              ),
            ),
            SizedBox(height: toSize(10)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _resultBody(BuildContext context, RecordingDetail detail) {
    return Scaffold(
      body: SafeArea(
        // ponytail: reserve the overlay even when the result is too short to scroll.
        minimum: EdgeInsets.only(bottom: 82 + MediaQuery.viewPaddingOf(context).bottom),
        child: ListView(
          padding: EdgeInsets.all(toSize(16)),
          children: [
            Text(detail.patientName ?? detail.recordingId,
                style: Theme.of(context).textTheme.titleLarge),
            Text('${detail.status} - ${detail.createdAt}'),
            SizedBox(height: toSize(12)),
            ...buildRecordingResult(context, detail),
            SizedBox(height: toSize(12)),
            FilledButton(
              onPressed: () => recordingAndroidController!.clearResult(),
              child: const Text('New recording'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(ThemeData theme) {
    if (recordingAndroidController == null) return Container();

    final String minutes = recordingAndroidController!
        .formatNumber(recordingAndroidController!.recordDuration ~/ 60);
    final String seconds = recordingAndroidController!
        .formatNumber(recordingAndroidController!.recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: TextStyle(
          color: theme.colorScheme.primary,
          fontFamily: 'NunitoSans',
          fontWeight: FontWeight.w700,
          fontSize: toSize(18)),
    );
  }
}
