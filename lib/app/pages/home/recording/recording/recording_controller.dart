import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:med_voice/app/pages/home/recording/recording/recording_presenter.dart';
import 'package:med_voice/domain/entities/recording/recording_detail.dart';
import 'package:med_voice/domain/entities/recording_archive/recording_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../../common/base_controller.dart';
import '../../../../utils/global.dart';

class RecordingController extends BaseController {
  final RecordingPresenter _presenter;
  SpeechToText? speech;
  bool speechEnabled = false;
  bool speechAvailable = false;
  int recordDuration = 0;
  String guideText = 'Press the button and start speaking';
  double confidenceLevel = 1.0;
  String uploadLanguage = 'vi';
  String get selectedLocaleId => uploadLanguage == 'vi' ? 'vi_VN' : 'en_US';
  final audioRecorder = Record();
  StreamSubscription<RecordState>? recordSub;
  RecordState recordState = RecordState.stop;
  StreamSubscription<Amplitude>? amplitudeSub;
  Amplitude? amplitude;
  String audioPath = '';
  Timer? timer;
  TextEditingController recordingName = TextEditingController();
  String tempName = '';
  File? audioFile;
  bool isTheSameFile = false;
  bool isStartingRecording = false;
  String pathForDelete = '';
  RecordingDetail? uploadResult;

  RecordingController(audioRepository)
      : _presenter = RecordingPresenter(audioRepository) {
    initListeners();
  }

  @override
  void firstLoad() {
    recordSub = audioRecorder.onStateChanged().listen((newRecordState) {
      recordState = newRecordState;
      refreshUI();
    });
    amplitudeSub = audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      amplitude = amp;
      refreshUI();
    });

    speech = SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    speechAvailable = await speech!.initialize(
      onError: errorListener,
      onStatus: statusListener,
      options: [SpeechToText.webDoNotAggregate],
    );
    refreshUI();
  }

  void statusListener(String status) async {
    debugPrint("status $status");
    if (status == "done" && speechEnabled) {
      await startListening();
    }
  }

  void errorListener(SpeechRecognitionError error) {
    debugPrint(error.errorMsg.toString());
  }

  @override
  void onListener() {
    _presenter.onUploadRecordingSuccess = (RecordingDetail detail) {
      uploadResult = detail;
      onDelete(pathForDelete);
      hideLoadingProgress();
      refreshUI();
      debugPrint("Upload recording succeeded: ${detail.recordingId}");
    };
    _presenter.onUploadRecordingFailed = (e) {
      view.showErrorFromServer("Upload recording failed: $e");
      hideLoadingProgress();
      debugPrint("Upload recording failed");
    };
  }

  Future<void> startListening() async {
    try {
      if (await audioRecorder.hasPermission()) {
        if (isTheSameFile == false) {
          view.showSaveRecordingPopup(
              'Enter the patient name', 'Save', 'Cancel', () {
            Navigator.pop(view.context);
            initializeSpeechLib();
          }, () {
            recordingName.clear();
            Navigator.pop(view.context);
          }, recordingName);
        } else {
          initializeSpeechLib();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> initializeSpeechLib() async {
    if (isStartingRecording == false) {
      final isSupported =
          await audioRecorder.isEncoderSupported(AudioEncoder.aacLc);
      debugPrint('${AudioEncoder.aacLc.name} supported: $isSupported');
      Directory? dir;
      if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = (await getExternalStorageDirectory());
        }
      }
      await audioRecorder.start(
          path: '${dir?.path}/${recordingName.text.replaceAll(' ', '-')}.m4a');
      isStartingRecording = true;
      isTheSameFile = true;
    }
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      view.setState(() {
        recordDuration++;
      });
    });
    tempName = recordingName.text.replaceAll(' ', '-');

    await speech!.listen(
      onResult: onSpeechResult,
      localeId: selectedLocaleId,
      listenOptions:
          SpeechListenOptions(cancelOnError: false, partialResults: true),
    );
    speechEnabled = true;
    refreshUI();
  }

  Future<void> stopListening() async {
    isTheSameFile = false;
    isStartingRecording = false;
    speechEnabled = false;
    timer?.cancel();
    final duration = recordDuration;
    recordDuration = 0;
    final path = await audioRecorder.stop();
    if (path != null) {
      view.showPopupWithAction(
          'Recording finished! Kindly wait as audio is now being processed',
          'okay');
      audioPath = path;
      pathForDelete = path;
    } else {
      debugPrint('path is empty');
    }
    await speech!.stop();
    onSaveRecordingToList(tempName, duration, audioPath);
    recordingName.clear();
    refreshUI();
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    debugPrint("Speech recognized: ${result.recognizedWords}");
    view.setState(() {
      guideText = result.recognizedWords;
    });
    debugPrint("guideText updated to: $guideText");
  }

  void onSaveRecordingToList(String title, int duration, String path) {
    RecordingInfo item = RecordingInfo(
        path: path, recordingTitle: title, duration: duration, isToggle: false);
    Global.sampleData.add(item);
    audioFile = File(path);
    audioPath = '';
    if (audioFile != null) {
      onUploadAudioFile(audioFile!, title);
    }
    refreshUI();
  }

  void onUploadAudioFile(File file, String? patientName) {
    showLoadingProgress();
    _presenter.executeUploadRecording(file, patientName, uploadLanguage);
  }

  Future<void> pickAndUploadAudio() async {
    if (speechEnabled || isStartingRecording) return;
    final String? path;
    try {
      path = await _presenter.pickAudioFile();
    } catch (e) {
      view.showErrorFromServer("Could not open file: $e");
      return;
    }
    if (path == null) return;
    view.showSaveRecordingPopup('Enter the patient name', 'Upload', 'Cancel',
        () {
      Navigator.pop(view.context);
      // Never delete a user-picked file; also drops a stale recording path.
      pathForDelete = '';
      onUploadAudioFile(File(path!), recordingName.text.replaceAll(' ', '-'));
      recordingName.clear();
    }, () {
      recordingName.clear();
      Navigator.pop(view.context);
    }, recordingName);
  }

  void setUploadLanguage(String lang) {
    uploadLanguage = lang;
    refreshUI();
  }

  void clearResult() {
    uploadResult = null;
    guideText = 'Press the button and start speaking';
    refreshUI();
  }

  Future<void> onDelete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint("File deleted successfully: $path");
        path = '';
        refreshUI();
      } else {
        debugPrint("File does not exist: $path");
      }
    } catch (e) {
      debugPrint("Failed to delete file: $e");
    }
  }

  String formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }
    return numberStr;
  }
}
