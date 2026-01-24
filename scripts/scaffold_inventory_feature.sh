#!/usr/bin/env bash
set -eu

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

echo "Scaffold already applied in repo. This script shows the created layout." 

tree -a -I ".git|build|ios|android|.dart_tool|.idea|.gradle" lib | sed -n '1,200p'

echo "\nRun 'flutter pub get' to fetch new dependencies." 
