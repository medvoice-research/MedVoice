# Changelog

All notable changes to the MedVoice mobile app are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/). The version matches
`version:` in `pubspec.yaml`.

## [Unreleased]

## [1.0.0] - 2026-10-26

First release. Tested end to end on a physical iPhone 15 Pro (iOS 26.3) against
medvoice-service 0.1.0, and on the iOS 26.5 simulator.

### Added
- Recordings flow wired to the medvoice-service `/recordings` API: record, upload,
  archive list, detail view and delete (#45).
- Login screen wired to `POST /auth/login` with error handling for the seeded mock
  accounts (sign-up is not wired yet).
- Audio replay: **Play recording** on the detail screen, using the server's `audio_url`.
- Vietnamese / English upload-language toggle on the recorder (default Vietnamese).
- Upload an existing audio file through the same pipeline as a live recording.
- Medical-term review: terms corrected from the audio and terms to verify, shown on the
  result and archive detail screens (or a warning when the term check could not run).
- `BACKEND_ENDPOINT` setting: the backend URL is read from a gitignored `.env`
  (template in `.env.example`) and compiled in with `--dart-define-from-file=.env`.
- Make targets: `env`, `tunnel-env` (write the running Cloudflare tunnel URL into
  `.env`), `local-env`, `print-endpoint`, `run`, `ios-sim`, `ios-device` (signed
  release build installed on a real iPhone) and `sim-speech-reset`.
- `scripts/sim-speech-reset.sh`: re-enables live transcription on the iOS simulator.
- README sections for running on a real iPhone and for how recording and live
  transcription interact.

### Fixed
- iOS recordings no longer come out silent or 0.2 s long: a failing live preview used to
  restart about 7 times a second, and each restart cut off the recorder. The preview now
  starts before the recorder, restarts only after normal pauses, and is capped. When it
  is unavailable the screen says so and recording continues.
- Vietnamese text no longer shows as mojibake (responses are decoded as UTF-8).
- PHI banner shows readable, deduplicated lines instead of raw `{type, start, end}` data.
- SOAP sections no longer start with stray `**` markdown.
- Recorder layout: microphone and language selector stay reachable on compact screens,
  result actions stay above the tab bar, and the bottom bar respects the home indicator.
- Upload language is kept across stop/start; audio URLs keep the backend path prefix.
- Android: the file-picker cache is cleared around uploads.

### Known limitations
- iOS simulator: live transcription works for one session per language; run
  `make sim-speech-reset` before each live-text test. Real iPhones are not affected.
- Android live preview uses the bundled English-only Vosk model.
- A rejected silent upload is shown as the raw server error text.
- Builds signed with a free Apple ID stop launching after 7 days.

[Unreleased]: https://github.com/medvoice-research/MedVoice/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/medvoice-research/MedVoice/releases/tag/v1.0.0
