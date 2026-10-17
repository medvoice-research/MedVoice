import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:med_voice/app/pages/home/recording/recording/recording_presenter.dart';
import 'package:med_voice/domain/entities/recording/recording_detail.dart';
import 'package:med_voice/domain/entities/recording_archive/recording_info.dart';
import 'package:path_provider/path_provider.dart';

import 'package:record/record.dart';
// Real vosk on mobile; dart:ffi-free stub on web (vosk cannot compile to JS).
import 'vosk_io.dart' if (dart.library.js_interop) 'vosk_web.dart';

import '../../../../../common/base_controller.dart';
import '../../../../utils/global.dart';

class RecordingAndroidController extends BaseController {
  final RecordingPresenter _presenter;
  bool speechEnabled = false;
  int recordDuration = 0;
  String guideText = 'Press the button and start speaking';
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
  ModelLoader? modelLoader;
  VoskFlutterPlugin vosk = VoskFlutterPlugin.instance();
  Model? modelController;
  Recognizer? recognizerController;
  SpeechService? speechServiceController;
  int sampleRate = 16000;
  String? error;
  List<String> resultTranscript = [];
  List<String> resultTranscriptFiltered = [];
  String enModelName = 'assets/vosk_model/vosk-model-small-en-us-0.15.zip';
  String vnModelName = 'vosk-model-vn-0.4.zip';
  // ponytail: vosk live text stays English (only en model bundled); server transcript follows uploadLanguage.
  String uploadLanguage = 'vi';

  RecordingAndroidController(audioRepository)
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
    modelLoader = ModelLoader();
    _initSpeech();
  }

  _initSpeech() async {
    showLoadingProgress();
    if (modelLoader != null) {
      try {
        String modelPath = await modelLoader!.loadFromAssets(enModelName);
        debugPrint("Model path: $modelPath");

        var model = await vosk.createModel(modelPath);
        modelController = model;
        debugPrint("Model created successfully");

        var recognizer = await vosk.createRecognizer(
          model: modelController!,
          sampleRate: sampleRate,
        );
        recognizerController = recognizer;

        var speechService = await vosk.initSpeechService(recognizerController!);
        speechServiceController = speechService;
      } catch (e) {
        error = "Initialization error: ${e.toString()}";
        debugPrint(error);
        view.showErrorFromServer(error);
      }
    } else {
      debugPrint("modelLoader is null");
    }

    refreshUI();
    hideLoadingProgress();
  }

  void statusListener(String status) async {
    debugPrint("status $status");
    if (status == "done" && speechEnabled) {
      await startListening();
    }
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

    if (speechServiceController != null) {
      await speechServiceController!.start();
    }
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
    // await speech!.stop();
    if (speechServiceController != null) {
      await speechServiceController!.stop();
    }
    onSaveRecordingToList(tempName, duration, audioPath);
    addUniqueStrings(resultTranscript);
    recordingName.clear();
    refreshUI();
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

  void setUploadLanguage(String lang) {
    uploadLanguage = lang;
    refreshUI();
  }

  void clearResult() {
    uploadResult = null;
    resultTranscript = [];
    resultTranscriptFiltered = [];
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

  String decodePartialTranscript(String data) {
    final convertedData = jsonDecode(data);
    return convertedData['partial'];
  }

  String decodeCompleteTranscript(String data) {
    final convertedData = jsonDecode(data);
    resultTranscript.add(convertedData['text']);
    return convertedData['text'];
  }

  void addUniqueStrings(List<String> unfilteredString) {
    resultTranscriptFiltered = [];
    for (String str in unfilteredString) {
      if (resultTranscriptFiltered.isEmpty || resultTranscriptFiltered.last != str) {
        debugPrint("DATA FILTERED: $str");
        resultTranscriptFiltered.add(str);
      }
    }
    refreshUI();
  }
}
