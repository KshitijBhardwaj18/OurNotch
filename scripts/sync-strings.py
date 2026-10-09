#!/usr/bin/env python3
"""Keeps OurNotch/Localizable.xcstrings in step with the code, for command-line builds.

Xcode updates the String Catalog when you build in the app; `xcodebuild` doesn't. After an
`xcodebuild build`, this adds strings found in the code, marks ones no longer used as stale,
and lists strings still missing a French or German translation (exit 1 with --check).

    xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData build
    python3 scripts/sync-strings.py --check
"""
import glob, json, sys

CATALOG = "OurNotch/Localizable.xcstrings"
LANGUAGES = ("fr", "de")
EXTRACTED = "build/DerivedData/Build/Intermediates.noindex/OurNotch.build/Debug/OurNotch.build/Objects-normal/*/*.stringsdata"

def code_keys():
    keys = set()
    for path in glob.glob(EXTRACTED):
        data = json.load(open(path))
        if "/Debug/" in data["source"]:  # the Partner Simulator is a test tool, English only
            continue
        keys |= {entry["key"] for entry in data["tables"].get("Localizable", [])}
    return keys

def main():
    keys = code_keys()
    if not keys:
        sys.exit("No extracted strings found: run xcodebuild build first.")
    catalog = json.load(open(CATALOG))
    strings = catalog["strings"]
    for key in keys - strings.keys():
        strings[key] = {}
    for key, entry in strings.items():
        if key in keys:
            entry.pop("extractionState", None)
        else:
            entry["extractionState"] = "stale"
    catalog["strings"] = dict(sorted(strings.items()))
    with open(CATALOG, "w") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False, separators=(",", " : "))
        f.write("\n")

    missing = [k for k in sorted(keys) if strings[k].get("shouldTranslate", True)
               and any(lang not in strings[k].get("localizations", {}) for lang in LANGUAGES)]
    for key in missing:
        print("needs translation:", repr(key))
    print(f"{len(keys)} strings in code, {len(missing)} missing a translation")
    if "--check" in sys.argv and missing:
        sys.exit(1)

if __name__ == "__main__":
    main()
