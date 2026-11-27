#!/usr/bin/env bash
# Regression gate. Run before declaring any enhancement done:
#   scripts/regression_check.sh
# 1) static analysis  2) feature registry guard  3) regression tests
set -u
cd "$(dirname "$0")/.."
fail=0

echo "== 1/3 dart analyze lib =="
dart analyze lib || fail=1

echo; echo "== 2/3 feature guard =="
python3 scripts/feature_guard.py check || fail=1

echo; echo "== 3/3 regression tests =="
flutter test test/regression || fail=1

echo; echo "== Features touched by your uncommitted changes =="
python3 scripts/feature_guard.py impact --changed

echo
if [ "$fail" -eq 0 ]; then echo "REGRESSION GATE: PASS"; else echo "REGRESSION GATE: FAIL"; fi
exit "$fail"
