import AppKit

protocol AppTrackerDelegate: AnyObject {
    func appListDidChange()
}

class AppTracker {
    weak var delegate: AppTrackerDelegate?
    private(set) var mruApps: [NSRunningApplication] = []

    private let workspace = NSWorkspace.shared
    private var observations: [NSObjectProtocol] = []

    init() {
        mruApps = workspace.runningApplications.filter {
            $0.activationPolicy == .regular
        }

        let nc = workspace.notificationCenter
        observations = [
            nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification,
                           object: nil, queue: .main) { [weak self] in self?.appLaunched($0) },
            nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification,
                           object: nil, queue: .main) { [weak self] in self?.appTerminated($0) },
            nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                           object: nil, queue: .main) { [weak self] in self?.appActivated($0) },
        ]
    }

    deinit {
        observations.forEach { workspace.notificationCenter.removeObserver($0) }
    }

    private func app(from note: Notification) -> NSRunningApplication? {
        note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    }

    private func appLaunched(_ note: Notification) {
        guard let a = app(from: note), a.activationPolicy == .regular else { return }
        guard !mruApps.contains(where: { $0.processIdentifier == a.processIdentifier }) else { return }
        mruApps.insert(a, at: 0)
        delegate?.appListDidChange()
    }

    private func appTerminated(_ note: Notification) {
        guard let a = app(from: note) else { return }
        let before = mruApps.count
        mruApps.removeAll { $0.processIdentifier == a.processIdentifier }
        if mruApps.count != before { delegate?.appListDidChange() }
    }

    private func appActivated(_ note: Notification) {
        guard let a = app(from: note), a.activationPolicy == .regular else { return }
        mruApps.removeAll { $0.processIdentifier == a.processIdentifier }
        mruApps.insert(a, at: 0)
        delegate?.appListDidChange()
    }
}
