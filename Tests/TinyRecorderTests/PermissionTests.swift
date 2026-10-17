import XCTest
import Combine
import AppKit
@testable import TinyRecorder

final class PermissionTests: XCTestCase {
    /// Regression: the old IOHID-only gate rejected this authorized configuration.
    func testAccessibilityAloneEnablesRecordingAndPlayback() {
        let state = AppState(permissionReader: { EventPermissions(accessibility: true, listening: false) })
        XCTAssertTrue(state.accessibilityGranted)
        XCTAssertTrue(state.canRecord)
    }

    func testListenOnlyAccessDoesNotEnablePlayback() {
        let state = AppState(permissionReader: { EventPermissions(accessibility: false, listening: true) })
        XCTAssertTrue(state.canRecord)
        XCTAssertFalse(state.accessibilityGranted)
    }

    func testNoAuthorizationLeavesActionsUnavailable() {
        let state = AppState(permissionReader: { EventPermissions(accessibility: false, listening: false) })
        XCTAssertFalse(state.canRecord)
        XCTAssertFalse(state.accessibilityGranted)
    }

    func testRecheckPublishesOneAtomicSnapshotWithoutTransientRevocation() {
        var access = EventPermissions(accessibility: true, listening: false)
        let state = AppState(permissionReader: { access })
        var snapshots: [EventPermissions] = []
        let observer = state.$permissions.dropFirst().sink { snapshots.append($0) }
        access = EventPermissions(accessibility: false, listening: true)
        state.refreshPermissions()
        XCTAssertTrue(state.canRecord)
        XCTAssertEqual(snapshots, [access])
        state.refreshPermissions()
        XCTAssertEqual(snapshots.count, 1)
        access = EventPermissions(accessibility: false, listening: false)
        state.refreshPermissions()
        XCTAssertFalse(state.canRecord)
        XCTAssertEqual(snapshots.count, 2)
        withExtendedLifetime(observer) {}
    }

    @MainActor
    func testReturningFromSettingsImmediatelyRefreshesAccess() {
        var access = EventPermissions(accessibility: false, listening: false)
        let state = AppState(permissionReader: { access })
        access = EventPermissions(accessibility: true, listening: false)
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertTrue(state.accessibilityGranted)
        XCTAssertTrue(state.canRecord)
    }
}
