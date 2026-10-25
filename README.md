# med_voice

MedVoice mobile app (Flutter): record or upload a clinical dictation, get the
transcript plus a SOAP / ICD-10 / PHI document from
[medvoice-service](https://github.com/medvoice-research/medvoice-service).

## Configurations when running the app

This project is being developed under Flutter sdk version 3.19.5 (pinned with
[fvm](https://fvm.app) - always run `fvm flutter ...`, never bare `flutter`).

After cloning, run `fvm flutter pub get`, then `make env` to create `.env`.
Run the tests with `fvm flutter test`.

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
make ios-device DEVICE_ID=<id> TEAM=<team>   # release build on a real iPhone (see below)
make sim-speech-reset       # re-enable simulator live transcription (see below)
make run DEVICE=<udid>      # fvm flutter run with the .env defines
```

Debug builds log `BACKEND_ENDPOINT = ...` at startup. A real phone cannot reach
your Mac's `localhost`: use `make tunnel-env` (Cloudflare quick tunnel:
`cloudflared tunnel --url http://localhost:8000`) or set your Mac's LAN IP. The
quick-tunnel URL changes every time the tunnel restarts - rerun
`make tunnel-env` and rebuild.

## Running on a real iPhone

1. Connect the iPhone (USB, unlocked), tap **Trust**, and enable
   Settings > Privacy & Security > **Developer Mode** (the phone restarts).
2. Sign in to Xcode with your Apple ID: Xcode > Settings > Accounts > `+`.
   A free Personal Team works; its apps stop launching after 7 days (rebuild).
3. Find your team ID and the device ID:
   ```bash
   defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier | grep teamID
   xcrun devicectl list devices
   ```
4. Point the app at a reachable backend (`make tunnel-env`), then build, sign,
   install and launch:
   ```bash
   make ios-device DEVICE_ID=<device id> TEAM=<team id>
   ```
   `TEAM` is passed on the command line, so the project's own team setting is
   not modified. If your team cannot use the bundle ID
   `vn.edu.rmit.capstone.medVoice`, change it in Xcode locally.
5. First launch only: Settings > General > VPN & Device Management > trust the
   developer profile, then open MedVoice.

## Recording and live transcription

Recording and live transcription are independent:

- The **recording** (`record` plugin) is what is uploaded; the transcript and
  document come from the server.
- The **live text** while recording comes from the iOS speech recognizer
  (`speech_to_text`) and is a preview only.

The live preview starts before the recorder. If the recognizer fails, the
screen shows "Live preview unavailable for this language - recording
continues" and the audio is still recorded and uploaded. The preview only
restarts after normal pauses (`error_no_match`, `error_speech_timeout`,
`error_retry`), with a cap, so a failing recognizer cannot interrupt the
recording (`LivePreviewPolicy`).

### Live transcription on the iOS simulator

The simulator cannot load iOS's on-device speech models. Live text works while
recognition uses Apple's online dictation, but after the first session that
recognizes speech, iOS switches that language to the on-device model and every
later attempt fails with `error_unknown (300)` - the screen then shows the
"Live preview unavailable" message (recording still works). Before each
live-text test on the simulator run:

```bash
make sim-speech-reset        # ~15 s: clears the model subscription, reboots, relaunches
```

That gives one working live-text session per language; log in again
afterwards. Real iPhones load the on-device models, so this should not be
needed there (not yet confirmed on a device). The simulator has no microphone of
its own: it uses the Mac's input (Simulator > I/O > Audio Input); a MacBook
with its lid closed records silence.

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
