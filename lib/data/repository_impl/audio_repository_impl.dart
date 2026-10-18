import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/recording/recording_detail.dart';
import '../../domain/entities/recording/recording_list.dart';
import '../../domain/repositories/audio_repository/audio_repository.dart';
import '../network/constants.dart';

class AudioRepositoryImpl implements AudioRepository {
  static final AudioRepositoryImpl _instance = AudioRepositoryImpl._internal();

  AudioRepositoryImpl._internal() : _client = http.Client();

  factory AudioRepositoryImpl() => _instance;

  // Injectable client for tests; defaults to the real http package.
  @visibleForTesting
  AudioRepositoryImpl.withClient(this._client);

  final http.Client _client;

  @override
  Future<RecordingDetail> uploadRecording({
    required Uint8List fileBytes,
    required String fileName,
    String? patientName,
    String language = 'en',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(Constants.recordings))
      ..files.add(http.MultipartFile.fromBytes('file', fileBytes,
          filename: fileName, contentType: MediaType('application', 'octet-stream')))
      ..fields['language'] = language;
    if (patientName != null) {
      request.fields['patient_name'] = patientName;
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }
    return RecordingDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  @override
  Future<RecordingList> listRecordings() async {
    final response = await _client.get(Uri.parse(Constants.recordings));
    if (response.statusCode != 200) {
      throw Exception('List failed: ${response.statusCode}');
    }
    return RecordingList.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  @override
  Future<RecordingDetail> getRecordingDetail(String recordingId) async {
    final response = await _client.get(Uri.parse(Constants.recordingDetail(recordingId)));
    if (response.statusCode != 200) {
      throw Exception('Get failed: ${response.statusCode}');
    }
    return RecordingDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRecording(String recordingId) async {
    final response = await _client.delete(Uri.parse(Constants.recordingDetail(recordingId)));
    if (response.statusCode != 204) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }
}
