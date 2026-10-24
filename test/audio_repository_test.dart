import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:med_voice/data/network/constants.dart';
import 'package:med_voice/data/repository_impl/audio_repository_impl.dart';

void main() {
  Constants.baseUrl = 'http://test.local:8000/';

  test('uploadRecording streams the file from disk and parses response', () async {
    final dir = await Directory.systemTemp.createTemp('upload_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/visit.mp3')..writeAsStringSync('AUDIO-BYTES');

    final mock = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/recordings');
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('filename="a.m4a"'));
      expect(request.body, contains('AUDIO-BYTES'));
      return http.Response(
        jsonEncode({
          'recording_id': 'rec_1', 'status': 'completed', 'created_at': 't',
          'patient_name': 'Jane', 'language': 'en',
          'transcript': {'full_text': 'Hello', 'segments': []},
          'medical_document': {'soap': {}, 'entities': [], 'phi': {'detected': false, 'entities': []}},
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = AudioRepositoryImpl.withClient(mock);
    final result = await repo.uploadRecording(
      filePath: file.path,
      fileName: 'a.m4a',
      patientName: 'Jane',
    );
    expect(result.recordingId, 'rec_1');
    expect(result.transcript.fullText, 'Hello');
  });

  test('listRecordings parses list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/recordings');
      return http.Response(
        jsonEncode({'recordings': [
          {'recording_id': 'rec_1', 'patient_name': null, 'created_at': 't', 'status': 'completed', 'has_medical_document': true}
        ]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = AudioRepositoryImpl.withClient(mock);
    final list = await repo.listRecordings();
    expect(list.recordings.length, 1);
    expect(list.recordings.first.recordingId, 'rec_1');
  });

  test('getRecordingDetail fetches by id', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/recordings/rec_1');
      return http.Response(
        jsonEncode({'recording_id': 'rec_1', 'status': 'completed', 'created_at': 't', 'patient_name': null, 'language': 'en',
          'transcript': {'full_text': 'X', 'segments': []},
          'medical_document': {'soap': {}, 'entities': [], 'phi': {'detected': false, 'entities': []}}}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = AudioRepositoryImpl.withClient(mock);
    final detail = await repo.getRecordingDetail('rec_1');
    expect(detail.recordingId, 'rec_1');
  });

  test('getRecordingDetail decodes Vietnamese as UTF-8 when the server sends no charset', () async {
    // FastAPI sends `application/json` without `charset`; package:http then falls back to Latin-1 for `body`.
    final mock = MockClient((request) async => http.Response.bytes(
          utf8.encode(jsonEncode({'recording_id': 'rec_1', 'status': 'completed', 'created_at': 't',
            'patient_name': 'Lê Thị Hoa', 'language': 'vi',
            'transcript': {'full_text': 'đau ngực trái', 'segments': []},
            'medical_document': {'soap': {}, 'entities': [], 'phi': {'detected': false, 'entities': []}}})),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final detail = await AudioRepositoryImpl.withClient(mock).getRecordingDetail('rec_1');
    expect(detail.patientName, 'Lê Thị Hoa');
    expect(detail.transcript.fullText, 'đau ngực trái');
  });

  test('deleteRecording expects 204', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'DELETE');
      return http.Response('', 204);
    });
    final repo = AudioRepositoryImpl.withClient(mock);
    await repo.deleteRecording('rec_1'); // should not throw
  });
}
