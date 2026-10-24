import 'package:flutter/material.dart';

import '../../domain/entities/recording/medical_document.dart';
import '../../domain/entities/recording/recording_transcript.dart';
import '../../domain/entities/recording/recording_detail.dart';
import '../../domain/entities/recording/soap_note.dart';
import 'result_text.dart';

/// Renders a [RecordingDetail] as a list of cards: transcript, SOAP note,
/// ICD-10 entities and the PHI banner. Shared by the recording screen (result
/// summary) and the recording detail screen.
List<Widget> buildRecordingResult(BuildContext context, RecordingDetail detail) {
  final MedicalDocument doc = detail.medicalDocument;
  return [
    _phiBanner(context, doc),
    ..._termChecks(context, detail.transcript),
    if (detail.transcript.fullText.isNotEmpty)
      _section(context, 'Transcript', Text(detail.transcript.fullText)),
    ..._soapSections(context, doc.soap),
    if (doc.entities.isNotEmpty)
      _section(
        context,
        'Medical entities',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in doc.entities)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.code.isEmpty ? e.name : '${e.name} (${e.code})',
                      ),
                    ),
                    if (e.category.isNotEmpty)
                      Chip(
                        label: Text(e.category),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
  ];
}

Widget _phiBanner(BuildContext context, MedicalDocument doc) {
  final List<String> lines = doc.phi.detected ? phiLines(doc.phi.entities) : const [];
  final bool detected = lines.isNotEmpty;
  final TextStyle style = TextStyle(color: detected ? Colors.red.shade900 : Colors.green.shade900);
  return Card(
    color: detected ? Colors.red.shade100 : Colors.green.shade100,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(detected ? Icons.warning_amber : Icons.verified_user,
              color: detected ? Colors.red.shade900 : Colors.green.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detected ? 'PHI detected' : 'No PHI detected', style: style),
                for (final line in lines) Text(line, style: style),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Medical-term guard: corrections made from the audio, and terms the doctor
/// must check. When the guard couldn't run, say so instead of staying silent.
List<Widget> _termChecks(BuildContext context, RecordingTranscript transcript) {
  final status = transcript.termCheckStatus;
  if (status == 'unavailable' || status == 'error') {
    return [
      Card(
        color: Colors.orange.shade100,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Medical term check unavailable: verify medicine and disease names against the audio.'),
        ),
      ),
    ];
  }
  if (transcript.termChecks.isEmpty) return const [];
  return [
    _section(
      context,
      'Medical terms to check',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in transcript.termChecks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(t.corrected
                  ? '"${t.original}" → ${t.replacement} (corrected from the audio)'
                  : '"${t.original}": check against the audio'
                      '${t.suggestions.isEmpty ? '' : '. Maybe: ${t.suggestions.take(3).join(', ')}'}'),
            ),
        ],
      ),
    ),
  ];
}

List<Widget> _soapSections(BuildContext context, SoapNote soap) {
  if (soap.isEmpty) return const [];
  return [
    for (final entry in {
      'Subjective': soap.subjective,
      'Objective': soap.objective,
      'Assessment': soap.assessment,
      'Plan': soap.plan,
    }.entries)
      if (entry.value.isNotEmpty)
        _section(context, entry.key, Text(entry.value)),
  ];
}

Widget _section(BuildContext context, String title, Widget child) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          child,
        ],
      ),
    ),
  );
}
