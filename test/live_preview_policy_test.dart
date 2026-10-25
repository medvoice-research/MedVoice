import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/pages/home/recording/recording/live_preview_policy.dart';

void main() {
  final t0 = DateTime(2026, 10, 25, 11, 0, 0);

  group('LivePreviewPolicy', () {
    test('regression: error_unknown (300) on iOS vi_VN stops the restart loop',
        () {
      final p = LivePreviewPolicy();
      p.onStarted(t0);
      expect(p.onError('error_unknown (300)'), isTrue);
      expect(p.shouldRestart(t0.add(const Duration(seconds: 5))), isFalse);
      expect(p.disabled, isTrue);
    });

    test('fatal named errors disable the preview', () {
      for (final e in [
        'error_language_not_supported',
        'error_language_unavailable',
        'error_permission',
        'error_audio_error',
        'error_too_many_requests',
        'error_listen_failed',
        'error_assets_not_installed',
      ]) {
        final p = LivePreviewPolicy();
        p.onStarted(t0);
        p.onError(e);
        expect(p.shouldRestart(t0.add(const Duration(seconds: 5))), isFalse,
            reason: e);
      }
    });

    test('normal pauses restart the preview', () {
      for (final e in ['error_no_match', 'error_speech_timeout', 'error_retry']) {
        final p = LivePreviewPolicy();
        p.onStarted(t0);
        expect(p.onError(e), isFalse, reason: e);
        expect(p.shouldRestart(t0.add(const Duration(seconds: 5))), isTrue,
            reason: e);
      }
    });

    test('regression: a session ending in under a second counts as failure',
        () {
      final p = LivePreviewPolicy();
      p.onStarted(t0);
      expect(p.shouldRestart(t0.add(const Duration(milliseconds: 150))), isFalse);
      expect(p.disabled, isTrue);
    });

    test('restarts are capped', () {
      final p = LivePreviewPolicy(maxRestarts: 3);
      var now = t0;
      for (var i = 0; i < 3; i++) {
        p.onStarted(now);
        now = now.add(const Duration(seconds: 30));
        expect(p.shouldRestart(now), isTrue);
      }
      p.onStarted(now);
      expect(p.shouldRestart(now.add(const Duration(seconds: 30))), isFalse);
    });

    test('reset re-enables for the next recording', () {
      final p = LivePreviewPolicy();
      p.onError('error_unknown (300)');
      p.reset();
      expect(p.disabled, isFalse);
      p.onStarted(t0);
      expect(p.shouldRestart(t0.add(const Duration(seconds: 5))), isTrue);
    });
  });
}
