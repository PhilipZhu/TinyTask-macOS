import XCTest
import SwiftUI
import AppKit
@testable import TinyRecorder

final class PermissionLayoutTests: XCTestCase {
    @MainActor
    func testOnboardingPermissionLayoutsFitWithAndWithoutAccess() async throws {
        for granted in [false, true] {
            let view = PermissionsStep(accessibility: granted, recordingAccess: granted,
                onAccessibility: {}, onRecording: {}, onRecheck: {}, onHelp: {})
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .background(Color(nsColor: .windowBackgroundColor))
            let host = NSHostingView(rootView: view)
            host.frame = NSRect(x: 0, y: 0, width: 560, height: 420)
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(nanoseconds: 100_000_000)
            XCTAssertLessThanOrEqual(host.fittingSize.height, 420)
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            if let output = ProcessInfo.processInfo.environment["TINYRECORDER_LAYOUT_OUTPUT"] {
                let url = URL(fileURLWithPath: output).appendingPathComponent("permission-\(granted ? "authorized" : "missing").png")
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: url)
            }
        }
    }
}
