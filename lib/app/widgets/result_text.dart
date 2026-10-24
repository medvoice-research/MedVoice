// Pure text helpers for the recording result view.

/// One display line per PHI entity, e.g. `Date, Age: "năm mươi hai tuổi" (patient)`.
///
/// Entities the backend could not locate in the transcript (start and end both
/// negative, e.g. the LLM's "không tìm thấy" = "not found" placeholder) are
/// dropped. Entities with the same text (trimmed, case-insensitive) are merged.
/// Legacy plain-string entities render as `"<text>"`.
List<String> phiLines(List<dynamic> entities) {
  final groups = <String, _PhiGroup>{};
  for (final e in entities) {
    final Map m = e is Map ? e : const {};
    if (_isNegative(m['start']) && _isNegative(m['end'])) continue;
    final text = (e is Map ? '${m['text'] ?? ''}' : '$e').trim();
    if (text.isEmpty) continue;
    final group = groups.putIfAbsent(text.toLowerCase(), () => _PhiGroup(text));
    final type = _capitalise('${m['type'] ?? ''}'.trim());
    if (type.isNotEmpty && !group.types.contains(type)) group.types.add(type);
    if (group.role.isEmpty) group.role = '${m['speaker_role'] ?? ''}'.trim();
  }
  return [for (final g in groups.values) '$g'];
}

class _PhiGroup {
  _PhiGroup(this.text);

  final String text;
  final List<String> types = [];
  String role = '';

  @override
  String toString() =>
      '${types.isEmpty ? '' : '${types.join(', ')}: '}"$text"${role.isEmpty ? '' : ' ($role)'}';
}

bool _isNegative(Object? v) => v is num && v < 0;

String _capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

final RegExp _bold = RegExp(r'\*\*(?=\S)(.+?)(?<=\S)\*\*');
final RegExp _edgeEmphasis = RegExp(r'^(?:\*\*|__)\s*|\s*(?:\*\*|__)$');

/// Strips markdown emphasis the LLM leaves in SOAP text (records stored before
/// the backend parser fix start with `** `): unwraps `**x**`, drops stray
/// leading/trailing `**`/`__`, trims. List bullets (`- `, `* `) are kept.
String cleanMarkdown(String text) =>
    text.trim().replaceAllMapped(_bold, (m) => m[1]!).replaceAll(_edgeEmphasis, '').trim();
