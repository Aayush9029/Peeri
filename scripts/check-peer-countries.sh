#!/bin/sh
set -eu
peeri_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
peeri_checks=$(mktemp -d "${TMPDIR:-/tmp}/peeri-country-checks.XXXXXX")
trap 'rm -rf "$peeri_checks"' EXIT HUP INT TERM
xcrun swiftc -parse-as-library \
    "$peeri_root/scripts/test-peer-countries.swift" \
    "$peeri_root/Peeri/Services/PeerCountryDatabase.swift" \
    "$peeri_root/Peeri/Views/Downloads/Detail/PeerLocation.swift" \
    -o "$peeri_checks/checks"
"$peeri_checks/checks" "$peeri_root/Peeri/Resources/PeerCountries.bin"
