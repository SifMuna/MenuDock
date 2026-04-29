#!/bin/bash
set -e

APP="MenuDock"
BUNDLE="${APP}.app"
MACOS="${BUNDLE}/Contents/MacOS"

echo "Cleaning..."
rm -rf "${BUNDLE}"
mkdir -p "${MACOS}"

echo "Compiling..."
swiftc \
  -framework AppKit \
  -framework Foundation \
  -O \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/AppTracker.swift \
  Sources/StatusBarController.swift \
  -o "${MACOS}/${APP}"

cp Info.plist "${BUNDLE}/Contents/"

echo "Signing (ad-hoc)..."
codesign --force --deep --sign - "${BUNDLE}"

echo ""
echo "Done: ${BUNDLE}"
echo "Run:  open ${BUNDLE}"
echo ""
echo "First launch: macOS Tahoe may require you to allow MenuDock in"
echo "  System Settings > Privacy & Security > Menu Bar"
