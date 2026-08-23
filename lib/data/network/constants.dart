class Constants {
  /// medvoice-service base URL. `localhost` works for the iOS simulator and an
  /// Android emulator via adb reverse; use the LAN IP or an ngrok URL for a
  /// physical device.
  static String baseUrl = "http://localhost:8000/";

  // Recordings API (medvoice-service contract v1)
  static String get recordings => "${baseUrl}recordings";
  static String recordingDetail(String id) => "${baseUrl}recordings/$id";

  /// POST /auth/login — mock-account login.
  static String get authLogin => "${baseUrl}auth/login";
}
