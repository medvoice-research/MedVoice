/// Fallback backend when no BACKEND_ENDPOINT define is passed at build time.
const String kDefaultBaseUrl = "http://localhost:8000/";

/// Trims whitespace and surrounding quotes and ensures exactly one trailing
/// `/`. An empty value falls back to [kDefaultBaseUrl].
String normalizeBaseUrl(String raw) {
  var value = raw.trim();
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    value = value.substring(1, value.length - 1).trim();
  }
  if (value.isEmpty) return kDefaultBaseUrl;
  return "${value.replaceFirst(RegExp(r'/+$'), '')}/";
}

class Constants {
  static const String defaultBaseUrl = kDefaultBaseUrl;

  /// medvoice-service base URL, compiled in from the `BACKEND_ENDPOINT` define.
  /// Set it in `.env` (see `.env.example`) and build with
  /// `--dart-define-from-file=.env` (`make run` / `make ios-sim` do this);
  /// `make tunnel-env` writes the running Cloudflare tunnel URL. Defaults to
  /// `http://localhost:8000/` (iOS simulator, Android via adb reverse).
  static String baseUrl = normalizeBaseUrl(const String.fromEnvironment(
      'BACKEND_ENDPOINT',
      defaultValue: kDefaultBaseUrl));

  // Recordings API (medvoice-service contract v1)
  static String get recordings => "${baseUrl}recordings";
  static String recordingDetail(String id) => "${baseUrl}recordings/$id";

  /// POST /auth/login — mock-account login.
  static String get authLogin => "${baseUrl}auth/login";
}
