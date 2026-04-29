# MenuDock

A macOS menu bar app that shows your running apps as icons — like a Dock, but inline in the menu bar.

## What it does

MenuDock fills configurable slots in the menu bar with icons of your most recently used apps. The most recent app is always on the left. When more apps are running than slots available, a **+** button appears on the right.

- **Left-click an icon** — activates that app
- **Left-click +** — opens a menu showing overflow apps (plus settings)
- **Right-click anywhere** — opens the settings menu (slot count 1–10, Quit)

Slot count persists across launches via `UserDefaults`.

## Requirements

- macOS (Tahoe / macOS 15+ tested)
- Swift compiler (`swiftc`) — included with Xcode Command Line Tools

## Build & run

```bash
bash build.sh
open MenuDock.app
```

The script compiles the Swift sources, assembles the `.app` bundle, and ad-hoc signs it.

**First launch:** macOS Tahoe may block the app. If the icons don't appear, open **System Settings → Privacy & Security → Menu Bar** and allow MenuDock.

## Configuration

Right-click any icon in the menu bar to open settings. Use the slot count submenu to choose how many app slots to display (1–10).

## Project structure

```
Sources/
  main.swift              — entry point
  AppDelegate.swift       — app lifecycle
  AppTracker.swift        — tracks running apps in MRU order
  StatusBarController.swift — menu bar rendering and interaction
build.sh                  — build script (no Xcode project needed)
Info.plist                — bundle metadata
```
