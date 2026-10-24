import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/widgets/recording_result_view.dart';
import 'package:med_voice/domain/entities/recording/recording_detail.dart';

Future<void> _pump(WidgetTester tester, RecordingDetail detail) {
  return tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) =>
          ListView(children: buildRecordingResult(context, detail)),
    ),
  ));
}

void main() {
  testWidgets('renders transcript, SOAP sections, entities and PHI warning',
      (tester) async {
    await _pump(
      tester,
      RecordingDetail.fromJson({
        'recording_id': 'rec_1',
        'status': 'completed',
        'created_at': 't',
        'patient_name': 'Jane Doe',
        'language': 'en',
        'transcript': {'full_text': 'Patient reports chest pain', 'segments': []},
        'medical_document': {
          'soap': {'subjective': 'chest pain', 'objective': '', 'assessment': 'angina', 'plan': ''},
          'entities': [
            {'name': 'Hypertension', 'code': 'I10', 'category': 'diagnosis', 'speaker': 'SPEAKER_00'}
          ],
          'phi': {'detected': true, 'entities': ['Jane Doe']},
        },
      }),
    );

    expect(find.text('Patient reports chest pain'), findsOneWidget);
    expect(find.text('Subjective'), findsOneWidget);
    expect(find.text('Assessment'), findsOneWidget);
    // Empty SOAP sections are hidden, not rendered blank.
    expect(find.text('Objective'), findsNothing);
    expect(find.text('Plan'), findsNothing);
    expect(find.text('Hypertension (I10)'), findsOneWidget);
    expect(find.text('diagnosis'), findsOneWidget);
    expect(find.text('PHI detected'), findsOneWidget);
    expect(find.text('"Jane Doe"'), findsOneWidget);
  });

  testWidgets('renders the clear banner and no SOAP card when document is empty',
      (tester) async {
    await _pump(
      tester,
      RecordingDetail.fromJson({
        'recording_id': 'rec_2',
        'status': 'completed',
        'created_at': 't',
        'patient_name': null,
        'language': 'en',
        'transcript': {'full_text': '', 'segments': []},
        'medical_document': {
          'soap': {},
          'entities': [],
          'phi': {'detected': false, 'entities': []},
        },
      }),
    );

    expect(find.text('No PHI detected'), findsOneWidget);
    expect(find.text('Transcript'), findsNothing);
    expect(find.text('Subjective'), findsNothing);
    expect(find.text('Medical entities'), findsNothing);
  });

  Map<String, dynamic> withReview(Map<String, dynamic> review) => {
        'recording_id': 'rec_3',
        'status': 'completed',
        'created_at': 't',
        'patient_name': null,
        'language': 'vi',
        'transcript': {'full_text': 'đang dùng metformin', 'segments': [], 'term_review': review},
        'medical_document': {'soap': {}, 'entities': [], 'phi': {'detected': false, 'entities': []}},
      };

  testWidgets('shows corrected and flagged medical terms', (tester) async {
    await _pump(
      tester,
      RecordingDetail.fromJson(withReview({
        'status': 'ok',
        'terms': [
          {'original': 'men hormone', 'replacement': 'metformin', 'action': 'corrected',
           'suggestions': [{'term': 'metformin', 'score': -3.6}]},
          {'original': 'tái hai', 'replacement': null, 'action': 'flagged',
           'suggestions': [{'term': 'type 2', 'score': -9.0}, {'term': 'tái phát', 'score': -12.0}]},
        ],
      })),
    );

    expect(find.text('Medical terms to check'), findsOneWidget);
    expect(find.text('"men hormone" → metformin (corrected from the audio)'), findsOneWidget);
    expect(find.text('"tái hai": check against the audio. Maybe: type 2, tái phát'), findsOneWidget);
  });

  testWidgets('warns when the term check could not run', (tester) async {
    await _pump(tester, RecordingDetail.fromJson(withReview({'status': 'unavailable', 'terms': []})));

    expect(find.textContaining('Medical term check unavailable'), findsOneWidget);
    expect(find.text('Medical terms to check'), findsNothing);
  });

  // rec_20261024_085430_df45e743 as served by GET /recordings/{id} (transcript trimmed).
  final evidence = {
    'recording_id': 'rec_20261024_085430_df45e743',
    'status': 'completed',
    'created_at': '2026-10-24T08:54:30.291604+00:00',
    'patient_name': 'Nguyễn Thị Lan',
    'language': 'vi',
    'transcript': {
      'full_text': 'bệnh nhân nữ năm mươi hai tuổi đến khám vì đau ngực trái và khó thở khi gắng sức',
      'segments': [],
    },
    'medical_document': {
      'soap': {
        'subjective': '** A 52-year-old female patient presents with chest pain and shortness of breath on exertion '
            'for the past two weeks. She has a history of hypertension and type 2 diabetes, both well-controlled. '
            'She currently takes metformin.',
        'objective': '** Blood pressure is 150/90 mmHg, pulse is 90/min, respiratory rate is 18/min.',
        'assessment': '** The patient presents with atypical chest pain.',
        'plan': '** N/A',
      },
      'entities': [],
      'phi': {
        'detected': true,
        'entities': [
          {'type': 'date', 'text': 'năm mươi hai tuổi', 'speaker_role': 'patient', 'start': 7, 'end': 11, 'confidence': 1.0},
          {'type': 'medical record number (mrn)', 'text': 'không tìm thấy', 'speaker_role': 'doctor', 'start': -1, 'end': -1, 'confidence': 0.8},
          {'type': 'age', 'text': 'năm mươi hai tuổi', 'speaker_role': 'patient', 'start': 7, 'end': 11, 'confidence': 1.0},
        ],
      },
    },
  };

  testWidgets('regression_phi_banner_prints_raw_maps', (tester) async {
    await _pump(tester, RecordingDetail.fromJson(evidence));

    expect(find.textContaining('{type:'), findsNothing);
    expect(find.textContaining('start:'), findsNothing);
    expect(find.textContaining('không tìm thấy'), findsNothing);
    expect(find.text('PHI detected'), findsOneWidget);
    expect(find.textContaining('"năm mươi hai tuổi"'), findsOneWidget);
  });

  testWidgets('shows the clear banner when every PHI entity is unlocated', (tester) async {
    await _pump(
      tester,
      RecordingDetail.fromJson({
        ...evidence,
        'medical_document': {
          'soap': {},
          'entities': [],
          'phi': {
            'detected': true,
            'entities': [
              {'type': 'medical record number (mrn)', 'text': 'không tìm thấy', 'speaker_role': 'doctor', 'start': -1, 'end': -1},
            ],
          },
        },
      }),
    );

    expect(find.text('No PHI detected'), findsOneWidget);
    expect(find.text('PHI detected'), findsNothing);
  });
}
