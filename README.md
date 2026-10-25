# med_voice

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configurations when running the app

This project is being developed under Flutter sdk version 3.19.5. Make sure your local IDE's sdk version the same as us.

After cloning the project, make sure to flutter pub get to install the app's neccessary library packages for the build.

Locate and run the main.dart file to start building the application.

## Backend

The app talks to [medvoice-service](https://github.com/medvoice-research/medvoice-service)
over its `/recordings` API (multipart upload of a recorded or picked audio file -> transcript + SOAP/ICD-10/PHI
document; list, get, delete, audio replay) and `/auth/login` (mock-account
authentication).

Set `BACKEND_ENDPOINT` in `.env` (gitignored; template in `.env.example`).
It is compiled in via `--dart-define-from-file=.env`, so rebuild after changing
it. Default: `http://localhost:8000/` (iOS simulator).

```bash
make env                    # create .env from .env.example if missing
make tunnel-env             # write the running Cloudflare quick-tunnel URL into .env
make local-env              # back to http://localhost:8000/
make print-endpoint         # show the current value
make ios-sim                # build + install + launch on the booted iOS simulator
make run DEVICE=<udid>      # fvm flutter run with the .env defines
```

Debug builds log `BACKEND_ENDPOINT = ...` at startup.

The recorder defaults uploads to Vietnamese; choose English before recording
to change the server transcription language. iOS live dictation follows the
selection. Android live preview uses the bundled English-only model; the
uploaded recording still uses the selected server language.

When the backend term guard runs, the recording result and archive detail show
terms corrected from audio and terms to verify. If the guard cannot run, the
result warns to check medicine and disease names against the audio; older
recordings without `transcript.term_review` display normally.

### Mock accounts

Seeded by the backend on startup (idempotent). Login validates against
`POST /auth/login`:

| email | password | role |
|---|---|---|
| `doctor@medvoice.local` | `MedVoice2026!` | physician |
| `nurse@medvoice.local` | `MedVoice2026!` | nurse |
| `admin@medvoice.local` | `Admin2026!` | admin |

Wrong password / unknown email -> 401 `invalid_credentials`, shown as
"Invalid email or password." on the login screen. App **signup is not wired
to the backend** yet.
