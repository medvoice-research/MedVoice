/// Decides whether the live speech preview may restart after the recognizer
/// reports "done", so a failing recognizer cannot loop and starve the recorder.
///
/// speech_to_text marks every error as permanent on both platforms, so the
/// error name - not the `permanent` flag - separates normal pauses from
/// failures.
class LivePreviewPolicy {
  /// Normal end-of-utterance / silence errors: the preview may restart.
  static const Set<String> recoverableErrors = {
    'error_no_match',
    'error_speech_timeout',
    'error_retry',
  };

  final int maxRestarts;
  final Duration minRunTime;

  bool _disabled = false;
  int _restarts = 0;
  DateTime? _startedAt;

  LivePreviewPolicy(
      {this.maxRestarts = 10, this.minRunTime = const Duration(seconds: 1)});

  bool get disabled => _disabled;
  int get restarts => _restarts;

  static bool isRecoverable(String errorMsg) =>
      recoverableErrors.contains(errorMsg.trim());

  /// New recording: re-enable the preview.
  void reset() {
    _disabled = false;
    _restarts = 0;
    _startedAt = null;
  }

  void onStarted(DateTime now) => _startedAt = now;

  /// Returns true when the error disabled the preview for this recording.
  bool onError(String errorMsg) {
    if (!isRecoverable(errorMsg)) _disabled = true;
    return _disabled;
  }

  /// Called when the recognizer reports "done" while still recording.
  /// A session that ended faster than [minRunTime] counts as a failure.
  bool shouldRestart(DateTime now) {
    if (_disabled) return false;
    final startedAt = _startedAt;
    if (startedAt != null && now.difference(startedAt) < minRunTime) {
      _disabled = true;
      return false;
    }
    if (_restarts >= maxRestarts) {
      _disabled = true;
      return false;
    }
    _restarts++;
    return true;
  }
}
