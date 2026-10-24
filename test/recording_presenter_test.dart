import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/pages/home/recording/recording/recording_presenter.dart';
import 'package:med_voice/domain/entities/recording/recording_detail.dart';
import 'package:med_voice/domain/entities/recording/recording_list.dart';
import 'package:med_voice/domain/repositories/audio_repository/audio_repository.dart';

void main() {
  test('passes the chosen language and nulls an empty patient name', () async {
    final dir = await Directory.systemTemp.createTemp('rec_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/visit.m4a')..writeAsBytesSync([1, 2, 3]);

    final repository = _FakeAudioRepository();
    final presenter = RecordingPresenter(repository);
    RecordingDetail? uploaded;
    presenter.onUploadRecordingSuccess = (RecordingDetail d) => uploaded = d;

    await presenter.executeUploadRecording(file, '', 'vi');

    expect(repository.lastLanguage, 'vi');
    expect(repository.lastPatientName, isNull);
    expect(repository.lastFileName, 'visit.m4a');
    expect(repository.lastFilePath, file.path);
    expect(uploaded, isNotNull);
  });
}

class _FakeAudioRepository implements AudioRepository {
  String? lastLanguage;
  String? lastPatientName;
  String? lastFileName;
  String? lastFilePath;

  @override
  Future<RecordingDetail> uploadRecording({
    required String filePath,
    required String fileName,
    String? patientName,
    String language = 'en',
  }) async {
    lastFileName = fileName;
    lastFilePath = filePath;
    lastPatientName = patientName;
    lastLanguage = language;
    return RecordingDetail.fromJson({'recording_id': 'r1', 'language': language});
  }

  @override
  Future<RecordingList> listRecordings() => throw UnimplementedError();

  @override
  Future<RecordingDetail> getRecordingDetail(String recordingId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRecording(String recordingId) => throw UnimplementedError();
}
