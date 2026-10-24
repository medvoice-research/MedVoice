@Tags(['integration'])
library recordings_api_integration_test;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:med_voice/data/network/constants.dart';
import 'package:med_voice/data/repository_impl/audio_repository_impl.dart';

/// End-to-end check of the recordings API against a REAL medvoice-service.
///
/// Uses a real [http.Client] (no [MockClient]) so the multipart encoding, status
/// codes and JSON shapes are verified against the actual backend rather than a
/// hand-written fixture. The `integration` tag keeps it out of the default
/// `flutter test` run; execute it explicitly with:
///
///     fvm flutter test --tags integration --run-skipped
const String _backendDownMessage =
    'backend not running — start docker compose in medvoice-service first';

/// Real consultation audio: English, ~49s. Not in this repo, so a missing file
/// skips rather than fails.
String get _sampleAudioPath =>
    '${Platform.environment['HOME']}/Projects/medvoice/datasets/audios/sg/sg-1.WAV';

/// Only connection-level failures mean "backend down". An HTTP error status is
/// left alone so a broken backend still fails the test instead of hiding.
Future<bool> _backendReachable(http.Client client) async {
  try {
    await client
        .get(Uri.parse(Constants.recordings))
        .timeout(const Duration(seconds: 5));
    return true;
  } on SocketException {
    return false;
  } on http.ClientException {
    return false;
  } on TimeoutException {
    return false;
  }
}

void main() {
  Constants.baseUrl = 'http://localhost:8000/';

  group('recordings API against real backend', () {
    test('uploads, lists, reads and deletes a real recording', () async {
      final client = http.Client();
      addTearDown(client.close);

      if (!await _backendReachable(client)) {
        markTestSkipped(_backendDownMessage);
        return;
      }

      final audio = File(_sampleAudioPath);
      if (!audio.existsSync()) {
        markTestSkipped('sample audio not found at $_sampleAudioPath');
        return;
      }

      final repo = AudioRepositoryImpl.withClient(client);

      // Delete the recording even if an assertion below fails, so a failing run
      // does not leave rows behind in a real backend.
      String? pendingId;
      addTearDown(() async {
        final id = pendingId;
        if (id == null) return;
        try {
          await repo.deleteRecording(id);
        } catch (_) {
          // Nothing to clean up.
        }
      });

      // 1. POST the real WAV. The backend transcribes synchronously, so this
      // single call takes ~30s — hence the explicit timeout on this test.
      final created = await repo.uploadRecording(
        filePath: audio.path,
        fileName: 'sg-1.WAV',
        patientName: 'Integration Test',
      );
      pendingId = created.recordingId;

      expect(created.recordingId, isNotEmpty);
      expect(created.status, 'completed');
      expect(created.transcript.fullText.trim(), isNotEmpty);

      // 2. The new recording appears in the list.
      final list = await repo.listRecordings();
      expect(
        list.recordings.map((r) => r.recordingId),
        contains(created.recordingId),
      );

      // 3. Detail by id returns the same recording.
      final detail = await repo.getRecordingDetail(created.recordingId);
      expect(detail.recordingId, created.recordingId);
      expect(detail.patientName, 'Integration Test');
      expect(detail.transcript.fullText, created.transcript.fullText);

      // 4. DELETE succeeds (204) and the recording is really gone.
      await repo.deleteRecording(created.recordingId);
      pendingId = null;

      final afterDelete = await repo.listRecordings();
      expect(
        afterDelete.recordings.map((r) => r.recordingId),
        isNot(contains(created.recordingId)),
      );
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
