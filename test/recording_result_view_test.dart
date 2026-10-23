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
    expect(find.text('PHI detected: Jane Doe'), findsOneWidget);
    expect(find.text('Medical terms to check'), findsNothing);
    expect(find.textContaining('Medical term check unavailable'), findsNothing);
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
           'suggestions': [{'term': 'type 2', 'score': -9.0}, {'term': 'tái phát', 'score': -12.0},
                           {'term': 'viêm phổi', 'score': -13.0}, {'term': 'ignore me', 'score': -15.0}]},
        ],
      })),
    );

    expect(find.text('Medical terms to check'), findsOneWidget);
    expect(find.text('"men hormone" → metformin (corrected from the audio)'), findsOneWidget);
    expect(find.text('"tái hai": check against the audio. Maybe: type 2, tái phát, viêm phổi'), findsOneWidget);
    expect(find.textContaining('ignore me'), findsNothing);
  });

  testWidgets('warns when the term check could not run', (tester) async {
    await _pump(tester, RecordingDetail.fromJson(withReview({'status': 'unavailable', 'terms': []})));

    expect(find.textContaining('Medical term check unavailable'), findsOneWidget);
    expect(find.text('Medical terms to check'), findsNothing);
  });
}
