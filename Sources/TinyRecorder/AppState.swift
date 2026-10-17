import Foundation
import SwiftUI
import Combine
import ApplicationServices
import CoreGraphics
import AppKit

/// Simple key code description used for hotkey labels.
struct HotkeyBinding: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var name: String
}

/// Accessibility authorizes event listening as well as posting. A missing
/// separate Input Monitoring grant must not block an Accessibility-authorized tap.
struct EventPermissions: Equatable {
    var accessibility: Bool
    var listening: Bool
    var canRecord: Bool { accessibility || listening }

    static func current() -> EventPermissions {
        EventPermissions(accessibility: AXIsProcessTrusted(), listening: CGPreflightListenEventAccess())
    }
}

/// User-configurable settings persisted in UserDefaults.
final class AppState: ObservableObject {
    @Published var loops: Int {
        didSet { UserDefaults.standard.set(loops, forKey: "loops") }
    }
    @Published var speed: Double {
        didSet { UserDefaults.standard.set(speed, forKey: "speed") }
    }
    @Published var recordHotkey: HotkeyBinding {
        didSet { persist(recordHotkey, key: "hk_record") }
    }
    @Published var stopHotkey: HotkeyBinding {
        didSet { persist(stopHotkey, key: "hk_stop") }
    }
    @Published var playHotkey: HotkeyBinding {
        didSet { persist(playHotkey, key: "hk_play") }
    }
    @Published var statusMessage: String = ""
    @Published var lastRecordedMacroID: UUID?
    /// Ephemeral UI state for the pre-record overlay. Kept here so every active
    /// surface can label the record toggle accurately while the countdown runs.
    @Published var recordingCountdownActive: Bool = false
    @Published private(set) var permissions: EventPermissions
    @Published var permissionTroubleshootingNeeded = false
    var accessibilityGranted: Bool { permissions.accessibility }
    var canRecord: Bool { permissions.canRecord }

    /// Pre-record countdown seconds. 0 disables.
    @Published var countdownSeconds: Int {
        didSet { UserDefaults.standard.set(countdownSeconds, forKey: "countdownSeconds") }
    }
    /// Optional sound feedback on record/stop/play.
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
            SoundController.shared.enabled = soundEnabled
        }
    }
    /// Show floating recording HUD when recording.
    @Published var showRecordingHUD: Bool {
        didSet { UserDefaults.standard.set(showRecordingHUD, forKey: "showRecordingHUD") }
    }
    /// Orders TinyTask's own windows out before synthetic input begins, so
    /// recorded coordinates can never click the library/editor that launched it.
    @Published var hideDuringPlayback: Bool {
        didSet { UserDefaults.standard.set(hideDuringPlayback, forKey: "hideDuringPlayback") }
    }
    /// Has the user finished onboarding?
    @Published var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }
    /// When true, the app runs menu-bar-only (no Dock icon, `.accessory`);
    /// when false it's a full Dock app (`.regular`).
    @Published var menuBarOnly: Bool {
        didSet { UserDefaults.standard.set(menuBarOnly, forKey: "menuBarOnly") }
    }

    private var refreshTimer: Timer?
    private var activationObserver: NSObjectProtocol?
    private let permissionReader: () -> EventPermissions

    init(permissionReader: @escaping () -> EventPermissions = EventPermissions.current) {
        self.permissionReader = permissionReader
        self.permissions = permissionReader()
        let d = UserDefaults.standard
        self.loops = normalizedLoopCount(d.object(forKey: "loops") as? Int ?? 1)
        self.speed = d.object(forKey: "speed") as? Double ?? 1.0
        self.recordHotkey = AppState.load(key: "hk_record")
            ?? HotkeyBinding(keyCode: KeyCode.f6, name: "F6")
        self.stopHotkey = AppState.load(key: "hk_stop")
            ?? HotkeyBinding(keyCode: KeyCode.f7, name: "F7")
        self.playHotkey = AppState.load(key: "hk_play")
            ?? HotkeyBinding(keyCode: KeyCode.f8, name: "F8")

        self.countdownSeconds = d.object(forKey: "countdownSeconds") as? Int ?? 3
        self.soundEnabled = d.object(forKey: "soundEnabled") as? Bool ?? false
        self.showRecordingHUD = d.object(forKey: "showRecordingHUD") as? Bool ?? true
        self.hideDuringPlayback = d.object(forKey: "hideDuringPlayback") as? Bool ?? true
        self.onboardingComplete = d.object(forKey: "onboardingComplete") as? Bool ?? false
        self.menuBarOnly = d.object(forKey: "menuBarOnly") as? Bool ?? false

        SoundController.shared.enabled = self.soundEnabled

        refreshPermissions()

        // Poll permission state while the app is alive so the warning banner
        // disappears shortly after the user grants access in System Settings.
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshPermissions()
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshPermissions() }
    }

    deinit {
        refreshTimer?.invalidate()
        if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
    }

    func refreshPermissions() {
        let latest = permissionReader()
        if latest != permissions { permissions = latest }
    }

    private func persist(_ binding: HotkeyBinding, key: String) {
        if let data = try? JSONEncoder().encode(binding) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func load(key: String) -> HotkeyBinding? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let b = try? JSONDecoder().decode(HotkeyBinding.self, from: data) else {
            return nil
        }
        return b
    }
}
