import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/domain/entities/recording/recording_detail.dart';
import 'package:med_voice/domain/entities/recording/recording_list.dart';
import 'package:med_voice/domain/entities/recording/recording_transcript.dart';
import 'package:med_voice/domain/entities/recording/create_recording_response.dart';

void main() {
  test('RecordingDetail.fromJson parses full contract response', () {
    final detail = RecordingDetail.fromJson({
      'recording_id': 'rec_1',
      'status': 'completed',
      'created_at': '2026-08-16T03:31:12Z',
      'patient_name': 'Jane Doe',
      'language': 'en',
      'transcript': {
        'full_text': 'Hello doctor',
        'segments': [
          {'speaker': 'SPEAKER_01', 'start': 0.0, 'end': 1.0, 'text': 'Hello doctor'}
        ],
      },
      'medical_document': {
        'soap': {'subjective': 's', 'objective': 'o', 'assessment': 'a', 'plan': 'p'},
        'entities': [
          {'name': 'Hypertension', 'code': 'I10', 'category': 'diagnosis', 'speaker': 'SPEAKER_00'}
        ],
        'phi': {'detected': false, 'entities': []},
      },
    });
    expect(detail.recordingId, 'rec_1');
    expect(detail.transcript.fullText, 'Hello doctor');
    expect(detail.transcript.segments.length, 1);
    expect(detail.medicalDocument.soap.assessment, 'a');
    expect(detail.medicalDocument.entities.length, 1);
    expect(detail.medicalDocument.entities.first.code, 'I10');
    expect(detail.medicalDocument.phi.detected, false);
  });

  test('term review tolerates omitted fields and ignores unknown fields', () {
    final legacy = RecordingTranscript.fromJson({'extra': 'ignored'});
    expect(legacy.termCheckStatus, '');
    expect(legacy.termChecks, isEmpty);

    final review = RecordingTranscript.fromJson({
      'term_review': {
        'status': 'ok',
        'extra': 'ignored',
        'terms': [
          {'original': 'tái hai', 'action': 'flagged', 'extra': true},
          {'original': 'men hormone', 'replacement': 'metformin',
           'suggestions': [{'term': 'metformin', 'score': -3.6, 'extra': true}]},
        ],
      },
    });
    expect(review.termCheckStatus, 'ok');
    expect(review.termChecks.first.corrected, isFalse);
    expect(review.termChecks.first.suggestions, isEmpty);
    expect(review.termChecks.last.corrected, isTrue);
    expect(review.termChecks.last.suggestions, ['metformin']);
  });

  test('RecordingDetail.fromJson parses audio_url when present, null when not',
      () {
    const minimalJson = {
      'recording_id': 'rec_x',
      'status': 'completed',
      'created_at': 't',
      'language': 'en',
      'transcript': {'full_text': '', 'segments': []},
      'medical_document': {
        'soap': {},
        'entities': [],
        'phi': {'detected': false, 'entities': []},
      },
    };

    final withAudio = RecordingDetail.fromJson({
      ...minimalJson,
      'audio_url': '/recordings/rec_x/audio',
    });
    expect(withAudio.audioUrl, '/recordings/rec_x/audio');

    expect(RecordingDetail.fromJson(minimalJson).audioUrl, isNull);
  });

  test('RecordingList.fromJson parses list response', () {
    final list = RecordingList.fromJson({
      'recordings': [
        {'recording_id': 'rec_1', 'patient_name': 'Jane Doe', 'created_at': '2026-08-16T03:31:12Z', 'status': 'completed', 'has_medical_document': true}
      ],
    });
    expect(list.recordings.length, 1);
    expect(list.recordings.first.hasMedicalDocument, true);
  });

  test('CreateRecordingResponse.fromJson parses POST response', () {
    final resp = CreateRecordingResponse.fromJson({
      'recording_id': 'rec_1', 'status': 'completed', 'created_at': 't', 'patient_name': null, 'language': 'en',
      'transcript': {'full_text': '', 'segments': []},
      'medical_document': {'soap': {}, 'entities': [], 'phi': {'detected': false, 'entities': []}},
    });
    expect(resp.recordingId, 'rec_1');
  });
}
