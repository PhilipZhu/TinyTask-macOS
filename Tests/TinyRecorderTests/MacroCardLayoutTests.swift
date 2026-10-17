import XCTest
import SwiftUI
import AppKit
@testable import TinyRecorder

final class MacroCardLayoutTests: XCTestCase {
    @MainActor
    func testDenseCardsAtMinimumAndPopoverWidths() async throws {
        let event = RecordedEvent(kind: .mouseMoved, time: 2.5, x: 0, y: 0, keyCode: 0, flags: 0,
                                  mouseButton: 0, clickCount: 0, scrollDeltaY: 0, scrollDeltaX: 0)
        let macro = SavedMacro(name: "Weekly report • Export & archive", events: [event],
                               icon: "doc.text", tags: ["work", "reports"], favorite: true,
                               hotkey: HotkeyBinding(keyCode: 96, name: "F5"), notes: "Export report", playCount: 12)
        for width in [232.0, 340.0] {
            for dark in [false, true] {
                let card = MacroCard(
                    macro: macro, isCurrent: true, isPlaying: false, playProgress: 0,
                    currentLoop: 0, totalLoops: 1, isSelected: false, isRenaming: false,
                    renameText: .constant(""), onSelect: { _ in }, onPlay: {}, onSchedule: {}, scheduled: true,
                    onEdit: {}, onDelete: {}, onDuplicate: {}, onExport: {}, onExportText: {},
                    onStartRename: {}, onCommitRename: {}, onSetLoops: { _ in }, onAssignHotkey: {},
                    onClearHotkey: {}, onToggleFavorite: {}, onSetIcon: { _ in }, onAddTag: {},
                    onDragMove: { _, _ in }, onOpenNotes: {}, onSetSpeed: { _ in }, onSetAccent: { _ in },
                    onSetChain: { _ in }, chainCandidates: [], chainTargetName: nil
                )
                .frame(width: width)
                .padding(16)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, dark ? .dark : .light)
                let host = NSHostingView(rootView: card)
                host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                host.frame = NSRect(x: 0, y: 0, width: width + 32, height: 146)
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(nanoseconds: 100_000_000)
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                if let output = ProcessInfo.processInfo.environment["TINYRECORDER_LAYOUT_OUTPUT"] {
                    let url = URL(fileURLWithPath: output).appendingPathComponent("card-\(Int(width))-\(dark ? "dark" : "light").png")
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: url)
                }
            }
        }
    }
}
