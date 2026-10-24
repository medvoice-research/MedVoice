import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/widgets/result_text.dart';

// phi.entities exactly as stored for rec_20261024_085430_df45e743.
const evidencePhi = [
  {'type': 'date', 'text': 'năm mươi hai tuổi', 'speaker_role': 'patient', 'start': 7, 'end': 11, 'confidence': 1.0},
  {'type': 'medical record number (mrn)', 'text': 'không tìm thấy', 'speaker_role': 'doctor', 'start': -1, 'end': -1, 'confidence': 0.8},
  {'type': 'age', 'text': 'năm mươi hai tuổi', 'speaker_role': 'patient', 'start': 7, 'end': 11, 'confidence': 1.0},
];

void main() {
  group('phiLines', () {
    test('merges same-text entities and drops the unlocated one', () {
      expect(phiLines(evidencePhi), ['Date, Age: "năm mươi hai tuổi" (patient)']);
    });

    test('drops an entity only when both start and end are negative', () {
      expect(
        phiLines([
          {'type': 'name', 'text': 'Lan', 'speaker_role': 'patient', 'start': -1, 'end': 4},
          {'type': 'name', 'text': 'không tìm thấy', 'speaker_role': 'doctor', 'start': -1, 'end': -1},
        ]),
        ['Name: "Lan" (patient)'],
      );
    });

    test('capitalises only the first letter of the type and omits a missing or empty role', () {
      expect(
        phiLines([
          {'type': 'medical record number (mrn)', 'text': 'MRN-42', 'start': 3, 'end': 9},
          {'type': 'phone', 'text': '0901 234 567', 'speaker_role': '', 'start': 12, 'end': 20},
        ]),
        ['Medical record number (mrn): "MRN-42"', 'Phone: "0901 234 567"'],
      );
    });

    test('merges text case- and space-insensitively without repeating a type', () {
      expect(
        phiLines([
          {'type': 'name', 'text': 'Nguyễn Thị Lan', 'speaker_role': 'patient', 'start': 0, 'end': 3},
          {'type': 'name', 'text': ' nguyễn thị lan ', 'speaker_role': 'patient', 'start': 9, 'end': 12},
        ]),
        ['Name: "Nguyễn Thị Lan" (patient)'],
      );
    });

    test('renders legacy plain-string entities quoted and deduped', () {
      expect(phiLines(['Jane Doe', ' jane doe', 'MRN 123']), ['"Jane Doe"', '"MRN 123"']);
    });

    test('is empty when every entity is unlocated', () {
      expect(phiLines([evidencePhi[1]]), isEmpty);
    });
  });
}
