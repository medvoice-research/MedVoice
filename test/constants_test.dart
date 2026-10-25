import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/data/network/constants.dart';

void main() {
  group('normalizeBaseUrl', () {
    test('adds a trailing slash', () {
      expect(normalizeBaseUrl('https://a.trycloudflare.com'),
          'https://a.trycloudflare.com/');
    });
    test('keeps a single trailing slash', () {
      expect(normalizeBaseUrl('http://x:8000/'), 'http://x:8000/');
    });
    test('collapses repeated trailing slashes', () {
      expect(normalizeBaseUrl('http://x:8000//'), 'http://x:8000/');
    });
    test('trims whitespace and surrounding quotes', () {
      expect(normalizeBaseUrl('  "https://a.b"  '), 'https://a.b/');
      expect(normalizeBaseUrl("'https://a.b/'"), 'https://a.b/');
    });
    test('empty falls back to localhost', () {
      expect(normalizeBaseUrl(''), 'http://localhost:8000/');
      expect(normalizeBaseUrl('   '), 'http://localhost:8000/');
    });
  });

  test('default base url is localhost when no define is passed', () {
    expect(Constants.defaultBaseUrl, 'http://localhost:8000/');
    expect(Constants.baseUrl, 'http://localhost:8000/');
  });
}
