#!/usr/bin/env bash
# Regenerate launcher icons and refresh builds after replacing assets/images/app_logo.png
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="${PATH:-}:${HOME}/flutter/bin:${HOME}/Library/Android/sdk/platform-tools"

if [ ! -f assets/images/app_logo.png ]; then
  echo "Missing assets/images/app_logo.png"
  exit 1
fi

echo "Regenerating Android/iOS launcher icons..."
dart run flutter_launcher_icons

echo "Cleaning Flutter build cache..."
flutter clean
flutter pub get

echo "Removing installed app (refreshes home-screen icon cache)..."
adb uninstall com.example.c_billing 2>/dev/null || true

echo ""
echo "Done. Start the app with a full reinstall:"
echo "  flutter run"
echo ""
echo "Important: hot reload/restart will NOT update the launcher icon or asset images."
