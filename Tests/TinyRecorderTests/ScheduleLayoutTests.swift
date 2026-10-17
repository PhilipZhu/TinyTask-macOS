import XCTest
import SwiftUI
import AppKit
@testable import TinyRecorder

/// Offscreen native rendering: no app launch, hotkeys, event capture, or input replay.
final class ScheduleLayoutTests: XCTestCase {
    func testAlarmHasNoHiddenSeconds() {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_037.25)
        let rounded = ScheduleView.alarmMinute(date)
        XCTAssertEqual(Calendar.current.component(.second, from: rounded), 0)
        XCTAssertEqual(rounded.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1), 0)
        XCTAssertLessThan(date.timeIntervalSince(rounded), 60)
    }

    @MainActor
    func testTimerAndAlarmLayouts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let event = RecordedEvent(kind: .mouseMoved, time: 1, x: 0, y: 0, keyCode: 0, flags: 0,
                                  mouseButton: 0, clickCount: 0, scrollDeltaY: 0, scrollDeltaX: 0)
        let macros = [SavedMacro(name: "Morning workspace", events: [event]),
                      SavedMacro(name: "Export weekly report", events: [event])]
        for mode in MacroSchedule.Mode.allCases {
            for dark in [false, true] {
                let scheduler = MacroScheduler(fileURL: directory.appendingPathComponent("\(mode)-\(dark).json"))
                XCTAssertTrue(scheduler.set(macroID: macros[0].id, fireDate: Date().addingTimeInterval(900), mode: mode))
                let view = ScheduleView(macros: macros, initialMacroID: macros[0].id, stopHotkey: "F7", onSchedule: { _, _, _ in false })
                    .environmentObject(scheduler)
                    .environment(\.colorScheme, dark ? .dark : .light)
                for size in [NSSize(width: 420, height: 480), NSSize(width: 400, height: 420)] {
                    let host = NSHostingView(rootView: view)
                    host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                    host.frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
                    host.layoutSubtreeIfNeeded()
                    try await Task.sleep(nanoseconds: 150_000_000)
                    host.layoutSubtreeIfNeeded()
                    let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    XCTAssertGreaterThanOrEqual(bitmap.pixelsWide, Int(size.width))
                    XCTAssertGreaterThanOrEqual(bitmap.pixelsHigh, Int(size.height))
                    if let output = ProcessInfo.processInfo.environment["TINYRECORDER_LAYOUT_OUTPUT"] {
                        let url = URL(fileURLWithPath: output).appendingPathComponent("\(mode.rawValue)-\(dark ? "dark" : "light")\(size.width == 400 ? "-minimum" : "").png")
                        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: url)
                    }
                }
            }
        }
    }
}
