SHELL := /bin/bash
.PHONY: publish
publish:
	git add .
	@while true; do \
		echo "Enter commit type:"; \
		echo "1. feature"; \
		echo "2. fix"; \
		echo "3. update"; \
		read -p "Choose a number from 1-3: " num; \
		case $$num in \
			1) type="feature"; break;; \
			2) type="fix"; break;; \
			3) type="update"; break;; \
			*) echo "Please choose again";; \
		esac; \
	done; \
	read -p "Enter commit message: " message; \
	git commit -m "$$type: $$message"
	git fetch
	git pull
	git push -u

# --- Backend endpoint (BACKEND_ENDPOINT in .env, compiled in via --dart-define-from-file) ---
METRICS ?= localhost:20241
SIM ?= booted
BUNDLE_ID := vn.edu.rmit.capstone.medVoice
DEFINES := --dart-define-from-file=.env

.PHONY: env tunnel-env local-env set-endpoint print-endpoint run ios-sim ios-device sim-speech-reset

env:
	@test -f .env || { cp .env.example .env; echo "created .env from .env.example"; }

# Write the running cloudflared quick-tunnel URL into .env
tunnel-env: env
	@host=$$(curl -s -m 3 http://$(METRICS)/quicktunnel | python3 -c 'import sys,json;print(json.load(sys.stdin).get("hostname",""))' 2>/dev/null); \
	if [ -z "$$host" ]; then echo "No cloudflared quick tunnel found at $(METRICS) - start: cloudflared tunnel --url http://localhost:8000"; exit 1; fi; \
	$(MAKE) --no-print-directory set-endpoint URL=https://$$host/

local-env: env
	@$(MAKE) --no-print-directory set-endpoint URL=http://localhost:8000/

# Replace (or add) the BACKEND_ENDPOINT line, keep everything else
set-endpoint:
	@test -n "$(URL)" || { echo "usage: make set-endpoint URL=https://host/"; exit 1; }
	@{ grep -v '^BACKEND_ENDPOINT=' .env; echo "BACKEND_ENDPOINT=$(URL)"; } > .env.tmp && mv .env.tmp .env
	@echo "BACKEND_ENDPOINT=$(URL)  (rebuild the app: make ios-sim)"

print-endpoint: env
	@grep '^BACKEND_ENDPOINT=' .env || echo "BACKEND_ENDPOINT not set (default http://localhost:8000/)"

run: env
	fvm flutter run $(DEFINES) $(if $(DEVICE),-d $(DEVICE)) $(ARGS)

ios-sim: env
	fvm flutter build ios --simulator --debug $(DEFINES)
	xcrun simctl install $(SIM) build/ios/iphonesimulator/Runner.app
	xcrun simctl launch $(SIM) $(BUNDLE_ID)

# Re-enable simulator live transcription (one session per language) - see README
sim-speech-reset:
	bash scripts/sim-speech-reset.sh $(SIM) $(BUNDLE_ID)

# Release build signed with YOUR team, installed + launched on a USB/Wi-Fi iPhone.
#   make ios-device DEVICE_ID=<id from: xcrun devicectl list devices> TEAM=<team id>
TEAM ?=
DEVICE_ID ?=
DEVICE_APP := build/device-dd/Build/Products/Release-iphoneos/Runner.app
ios-device: env
	@test -n "$(DEVICE_ID)" || { echo "set DEVICE_ID (xcrun devicectl list devices):"; xcrun devicectl list devices; exit 1; }
	fvm flutter build ios --config-only --release $(DEFINES)
	cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
	  -destination 'generic/platform=iOS' -allowProvisioningUpdates \
	  $(if $(TEAM),DEVELOPMENT_TEAM=$(TEAM)) -derivedDataPath ../build/device-dd build
	xcrun devicectl device install app --device $(DEVICE_ID) $(DEVICE_APP)
	xcrun devicectl device process launch --device $(DEVICE_ID) $(BUNDLE_ID) || \
	  echo "First install: on the iPhone trust the developer in Settings > General > VPN & Device Management, then open MedVoice"
