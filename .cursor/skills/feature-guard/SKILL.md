---
name: feature-guard
description: Check which existing c-billing features an enhancement touches and verify nothing regressed. Use before and after implementing any feature, enhancement or bug fix, or when asked to run regression checks or add a feature to the registry.
---

# Feature guard

Registry: `.cursor/feature-registry.json` (features, invariants, anchors, forbidden patterns, tests).

## Before coding
```
python3 scripts/feature_guard.py list
python3 scripts/feature_guard.py impact <file> [<file> ...]
```
Read each printed invariant; your change must keep them true.

## After coding
```
scripts/regression_check.sh
```
Runs `dart analyze lib`, `feature_guard.py check`, `flutter test test/regression`, then lists the features touched by uncommitted changes. All must pass.

## Adding or updating a feature
Add to `features` in the registry:
- `files`: path prefixes (end folders with `/`) so `impact` can find it
- `invariants`: plain-language rules that must keep holding
- `anchors`: `{file, contains}` strings that prove the feature still exists
- `forbidden`: `{file, contains, why}` patterns for bugs that must never return
- `tests`: regression tests in `test/regression/`

Only change an anchor or forbidden pattern when the story intentionally changes that behaviour, and mention it in the final report.
