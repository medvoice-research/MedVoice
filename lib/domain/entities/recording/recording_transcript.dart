import 'transcript_segment.dart';

class RecordingTranscript {
  final String fullText;
  final List<TranscriptSegment> segments;

  /// Medical-term guard result: '' (not run), 'ok', 'unavailable' or 'error'.
  final String termCheckStatus;
  final List<TermCheck> termChecks;

  RecordingTranscript({
    required this.fullText,
    required this.segments,
    this.termCheckStatus = '',
    this.termChecks = const [],
  });

  factory RecordingTranscript.fromJson(Map<String, dynamic> json) {
    final review = Map<String, dynamic>.from((json['term_review'] as Map?) ?? {});
    return RecordingTranscript(
      fullText: json['full_text'] as String? ?? '',
      segments: ((json['segments'] as List?) ?? [])
          .map((s) => TranscriptSegment.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      termCheckStatus: review['status'] as String? ?? '',
      termChecks: ((review['terms'] as List?) ?? [])
          .map((t) => TermCheck.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList(),
    );
  }
}

/// A suspected misheard medical term: corrected from the audio, or flagged for review.
class TermCheck {
  final String original;
  final String? replacement;
  final List<String> suggestions;

  TermCheck({required this.original, this.replacement, this.suggestions = const []});

  bool get corrected => replacement != null;

  factory TermCheck.fromJson(Map<String, dynamic> json) => TermCheck(
        original: json['original'] as String? ?? '',
        replacement: json['replacement'] as String?,
        suggestions: ((json['suggestions'] as List?) ?? [])
            .map((s) => (s as Map)['term'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}
