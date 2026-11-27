#!/usr/bin/env python3
"""Feature guard: protects existing functionality while the app is enhanced.

Commands (run from the repo root, python3 standard library only):

  feature_guard.py list                 Show every registered feature.
  feature_guard.py impact PATH [...]    Features + invariants touched by files.
  feature_guard.py impact --changed     Same, for files changed vs HEAD
                                        (staged, unstaged and untracked).
  feature_guard.py check                Verify all anchors exist and all
                                        forbidden patterns are absent.

`check` exits 1 if a registered feature was removed or a banned pattern came
back, so a silent regression becomes a loud failure.
"""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / ".cursor" / "feature-registry.json"


def load():
    with open(REGISTRY, encoding="utf-8") as f:
        return json.load(f)["features"]


def read(rel):
    p = ROOT / rel
    return p.read_text(encoding="utf-8") if p.exists() else None


def cmd_list(features):
    for f in features:
        print(f"- {f['id']}: {f['name']}")
        print(f"    files: {', '.join(f['files'])}")
        print(f"    anchors: {len(f['anchors'])}, forbidden: {len(f.get('forbidden', []))}, tests: {len(f.get('tests', []))}")
    return 0


def matches(feature, path):
    path = path.replace("\\", "/")
    for prefix in feature["files"]:
        if path == prefix or (prefix.endswith("/") and path.startswith(prefix)):
            return True
    return False


def changed_files():
    out = set()
    for args in (
        ["git", "diff", "--name-only", "HEAD"],
        ["git", "ls-files", "--others", "--exclude-standard"],
    ):
        try:
            res = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, check=True)
            out.update(l.strip() for l in res.stdout.splitlines() if l.strip())
        except Exception:
            pass
    return sorted(out)


def cmd_impact(features, paths):
    if paths == ["--changed"]:
        paths = changed_files()
        if not paths:
            print("No changed files.")
            return 0
    hit = {}
    for p in paths:
        for f in features:
            if matches(f, p):
                hit.setdefault(f["id"], (f, []))[1].append(p)
    if not hit:
        print("No registered feature touches these files (add one if this is new behaviour):")
        for p in paths:
            print(f"  {p}")
        return 0
    for fid, (f, files) in hit.items():
        print(f"\n[{fid}] {f['name']}")
        for p in files:
            print(f"  touched: {p}")
        print("  must still hold:")
        for inv in f["invariants"]:
            print(f"    - {inv}")
        if f.get("tests"):
            print(f"  tests: {', '.join(f['tests'])}")
    return 0


def cmd_check(features):
    problems = []
    for f in features:
        for prefix in f["files"]:
            if not (ROOT / prefix).exists():
                problems.append(f"[{f['id']}] registered path is gone: {prefix}")
        for a in f["anchors"]:
            text = read(a["file"])
            if text is None:
                problems.append(f"[{f['id']}] file missing: {a['file']}")
            elif a["contains"] not in text:
                problems.append(f"[{f['id']}] REMOVED: '{a['contains']}' no longer in {a['file']}")
        for b in f.get("forbidden", []):
            text = read(b["file"])
            if text is not None and b["contains"] in text:
                problems.append(f"[{f['id']}] BANNED pattern back: '{b['contains']}' in {b['file']} ({b.get('why', '')})")
        for t in f.get("tests", []):
            if not (ROOT / t).exists():
                problems.append(f"[{f['id']}] regression test missing: {t}")
    if problems:
        print("FEATURE GUARD FAILED:")
        for p in problems:
            print(f"  x {p}")
        print("\nIf the change is intentional, update .cursor/feature-registry.json in the same change.")
        return 1
    n = sum(len(f["anchors"]) + len(f.get("forbidden", [])) for f in features)
    print(f"Feature guard OK: {len(features)} features, {n} checks.")
    return 0


def main(argv):
    features = load()
    if len(argv) < 2 or argv[1] == "list":
        return cmd_list(features)
    if argv[1] == "impact":
        return cmd_impact(features, argv[2:] or ["--changed"])
    if argv[1] == "check":
        return cmd_check(features)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
