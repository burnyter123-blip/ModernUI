#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

ARCH="${ARCH:-x86_64}"

command -v flutter >/dev/null 2>&1 || { echo "Error: flutter not installed"; exit 1; }

flutter pub get
flutter build linux --release

BUNDLE="build/linux/x64/release/bundle"
[ -d "$BUNDLE" ] || { echo "Error: build bundle not found at $BUNDLE"; exit 1; }

cp arcader-frontend.json "$BUNDLE/arcader-frontend.json"

TARBALL="build/modern-frontend-linux-${ARCH}.tar.gz"
rm -f "$TARBALL"
tar czf "$TARBALL" -C "$BUNDLE" .
echo "Built $TARBALL"
