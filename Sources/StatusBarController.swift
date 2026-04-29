import AppKit

class StatusBarController: AppTrackerDelegate {
    private let statusItem: NSStatusItem
    private let tracker: AppTracker

    var slotCount: Int {
        didSet {
            UserDefaults.standard.set(slotCount, forKey: "MenuDock.slotCount")
            refresh()
        }
    }

    private var displayedApps: [NSRunningApplication] = []
    private var overflowApps: [NSRunningApplication] = []

    private let iconSize: CGFloat = 16
    private let iconSpacing: CGFloat = 4
    private let sidePadding: CGFloat = 4
    private let overflowGlyphWidth: CGFloat = 10
    private let barHeight: CGFloat = 22

    init() {
        let saved = UserDefaults.standard.integer(forKey: "MenuDock.slotCount")
        slotCount = saved > 0 ? saved : 5
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        tracker = AppTracker()
        tracker.delegate = self

        if let button = statusItem.button {
            button.action = #selector(handleClick(_:))
            button.target = self
            button.sendAction(on: NSEvent.EventTypeMask.leftMouseDown.union(.rightMouseDown))
        }

        refresh()
    }

    // MARK: - AppTrackerDelegate

    func appListDidChange() {
        refresh()
    }

    // MARK: - Private

    private func refresh() {
        displayedApps = Array(tracker.mruApps.prefix(slotCount))
        overflowApps = tracker.mruApps.count > slotCount
            ? Array(tracker.mruApps.dropFirst(slotCount))
            : []

        let hasOverflow = !overflowApps.isEmpty
        let width = computeWidth(appCount: displayedApps.count, hasOverflow: hasOverflow)
        statusItem.length = width
        statusItem.button?.image = renderImage(width: width, hasOverflow: hasOverflow)
        statusItem.button?.imagePosition = .imageOnly
    }

    private func computeWidth(appCount: Int, hasOverflow: Bool) -> CGFloat {
        guard appCount > 0 else { return sidePadding * 2 }
        var w = sidePadding * 2 + CGFloat(appCount) * iconSize
        if appCount > 1 { w += CGFloat(appCount - 1) * iconSpacing }
        if hasOverflow { w += iconSpacing + overflowGlyphWidth }
        return w
    }

    private func renderImage(width: CGFloat, hasOverflow: Bool) -> NSImage {
        let apps = displayedApps
        let iconSize = self.iconSize
        let iconSpacing = self.iconSpacing
        let sidePadding = self.sidePadding
        let overflowGlyphWidth = self.overflowGlyphWidth
        let barHeight = self.barHeight

        return NSImage(size: NSSize(width: width, height: barHeight), flipped: false) { _ in
            var x = sidePadding
            let y = (barHeight - iconSize) / 2

            for app in apps {
                let rect = NSRect(x: x, y: y, width: iconSize, height: iconSize)
                app.icon?.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
                x += iconSize + iconSpacing
            }

            if hasOverflow {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: NSColor.labelColor,
                ]
                let str = NSAttributedString(string: "+", attributes: attrs)
                let sz = str.size()
                str.draw(at: NSPoint(
                    x: x + (overflowGlyphWidth - sz.width) / 2,
                    y: (barHeight - sz.height) / 2
                ))
            }

            return true
        }
    }

    // MARK: - Click handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseDown {
            showSettingsMenu(sender: sender, event: event)
            return
        }

        let localX = sender.convert(event.locationInWindow, from: nil).x

        if let idx = iconIndex(at: localX) {
            activate(displayedApps[idx])
        } else if !overflowApps.isEmpty {
            showOverflowMenu(sender: sender, event: event)
        }
    }

    private func iconIndex(at x: CGFloat) -> Int? {
        let slotWidth = iconSize + iconSpacing
        let adjusted = x - sidePadding
        guard adjusted >= 0 else { return nil }
        let idx = Int(adjusted / slotWidth)
        guard idx < displayedApps.count else { return nil }
        // reject clicks that land in the gap between icons
        guard adjusted.truncatingRemainder(dividingBy: slotWidth) < iconSize else { return nil }
        return idx
    }

    private func activate(_ app: NSRunningApplication) {
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }

    // MARK: - Menus

    private func showOverflowMenu(sender: NSStatusBarButton, event: NSEvent) {
        let menu = NSMenu()
        for app in overflowApps {
            let item = NSMenuItem(
                title: app.localizedName ?? "Unknown",
                action: #selector(activateOverflowApp(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = app
            if let icon = app.icon {
                let img = icon.copy() as! NSImage
                img.size = NSSize(width: 16, height: 16)
                item.image = img
            }
            menu.addItem(item)
        }
        appendSettings(to: menu)
        NSMenu.popUpContextMenu(menu, with: event, for: sender)
    }

    private func showSettingsMenu(sender: NSStatusBarButton, event: NSEvent) {
        let menu = NSMenu()
        appendSettings(to: menu)
        NSMenu.popUpContextMenu(menu, with: event, for: sender)
    }

    private func appendSettings(to menu: NSMenu) {
        if !menu.items.isEmpty { menu.addItem(.separator()) }

        let slotsItem = NSMenuItem(title: "Slots", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for n in 1...10 {
            let item = NSMenuItem(title: "\(n)", action: #selector(setSlotCount(_:)), keyEquivalent: "")
            item.target = self
            item.tag = n
            item.state = (n == slotCount) ? .on : .off
            sub.addItem(item)
        }
        slotsItem.submenu = sub
        menu.addItem(slotsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit MenuDock",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
    }

    @objc private func activateOverflowApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        activate(app)
    }

    @objc private func setSlotCount(_ sender: NSMenuItem) {
        slotCount = sender.tag
    }
}
