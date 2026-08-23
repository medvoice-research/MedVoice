import 'medical_document.dart';
import 'recording_transcript.dart';

class RecordingDetail {
  final String recordingId;
  final String status;
  final String createdAt;
  final String? patientName;
  final String language;
  final RecordingTranscript transcript;
  final MedicalDocument medicalDocument;
  final String? audioUrl;

  RecordingDetail({
    required this.recordingId,
    required this.status,
    required this.createdAt,
    required this.patientName,
    required this.language,
    required this.transcript,
    required this.medicalDocument,
    this.audioUrl,
  });

  factory RecordingDetail.fromJson(Map<String, dynamic> json) => RecordingDetail(
        recordingId: json['recording_id'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        patientName: json['patient_name'] as String?,
        language: json['language'] as String? ?? 'en',
        transcript: RecordingTranscript.fromJson(
            Map<String, dynamic>.from((json['transcript'] as Map?) ?? {})),
        medicalDocument: MedicalDocument.fromJson(
            Map<String, dynamic>.from((json['medical_document'] as Map?) ?? {})),
        audioUrl: json['audio_url'] as String?,
      );
}
