import XCTest
@testable import TinyRecorder

final class MacroSchedulerTests: XCTestCase {
    private var directory: URL!
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private let macroID = UUID()

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }
    private var file: URL { directory.appendingPathComponent("schedules.json") }
    private func make() -> MacroScheduler { MacroScheduler(fileURL: file, now: now) }

    func testTimerAndAlarmPersistAndUpdateWithoutDuplicates() {
        let scheduler = make()
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(60), mode: .timer, now: now))
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(120), mode: .alarm, now: now))
        let restored = make()
        XCTAssertEqual(restored.schedules.count, 1)
        XCTAssertEqual(restored.pending.first?.mode, .alarm)
        XCTAssertEqual(restored.pending.first?.fireDate, now.addingTimeInterval(120))
    }

    func testDueRunIsConsumedBeforeCallbackAndRunsOnlyOnce() {
        let scheduler = make()
        var runs = 0
        scheduler.onRun = { id in
            XCTAssertEqual(id, self.macroID)
            XCTAssertTrue(self.make().pending.isEmpty)
            runs += 1
        }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(10), mode: .timer, now: now))
        scheduler.processDue(now: now.addingTimeInterval(9))
        XCTAssertEqual(runs, 0)
        scheduler.processDue(now: now.addingTimeInterval(10))
        scheduler.processDue(now: now.addingTimeInterval(11))
        XCTAssertEqual(runs, 1)
        XCTAssertEqual(scheduler.schedules.first?.status, .completed)
    }

    func testPastAndNonfiniteDatesAreRejected() {
        let scheduler = make()
        for date in [now, now.addingTimeInterval(-1), Date(timeIntervalSinceReferenceDate: .infinity)] {
            XCTAssertFalse(scheduler.set(macroID: macroID, fireDate: date, mode: .alarm, now: now))
        }
        XCTAssertTrue(scheduler.schedules.isEmpty)
    }

    func testOverdueOnRelaunchIsMissedAndNeverRuns() {
        let scheduler = make()
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(10), mode: .alarm, now: now))
        let restored = MacroScheduler(fileURL: file, now: now.addingTimeInterval(11))
        restored.onRun = { _ in XCTFail("Must not catch up on relaunch") }
        restored.processDue(now: now.addingTimeInterval(12))
        XCTAssertEqual(restored.schedules.first?.status, .missed)
    }

    func testSleepAndLateTimerDoNotCatchUp() {
        let scheduler = make()
        scheduler.onRun = { _ in XCTFail("Must not replay late") }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(10), mode: .timer, now: now))
        scheduler.suspend()
        scheduler.processDue(now: now.addingTimeInterval(10))
        XCTAssertEqual(scheduler.pending.count, 1)
        scheduler.resume(now: now.addingTimeInterval(11))
        XCTAssertEqual(scheduler.schedules.first?.status, .missed)
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(20), mode: .timer, now: now))
        scheduler.processDue(now: now.addingTimeInterval(26))
        XCTAssertEqual(scheduler.schedules.first?.status, .missed)
    }

    func testUnavailableRunIsBlockedWithoutRetry() {
        let scheduler = make()
        scheduler.unavailableReason = { _ in "Recording is active" }
        scheduler.onRun = { _ in XCTFail("Must not interrupt recording") }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(1), mode: .timer, now: now))
        scheduler.processDue(now: now.addingTimeInterval(1))
        scheduler.unavailableReason = nil
        scheduler.processDue(now: now.addingTimeInterval(2))
        XCTAssertEqual(scheduler.schedules.first?.status, .blocked)
        XCTAssertEqual(scheduler.schedules.first?.detail, "Recording is active")
    }

    func testSimultaneousRunsRespectBusyState() {
        let scheduler = make()
        var busy = false
        var runs = 0
        scheduler.unavailableReason = { _ in busy ? "Busy" : nil }
        scheduler.onRun = { _ in busy = true; runs += 1 }
        for id in [macroID, UUID()] {
            XCTAssertTrue(scheduler.set(macroID: id, fireDate: now.addingTimeInterval(1), mode: .timer, now: now))
        }
        scheduler.processDue(now: now.addingTimeInterval(1))
        XCTAssertEqual(runs, 1)
        XCTAssertEqual(scheduler.schedules.filter { $0.status == .blocked }.count, 1)
    }

    func testCancelAndDeletePersist() {
        let scheduler = make()
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(60), mode: .timer, now: now))
        XCTAssertTrue(scheduler.remove(macroID: macroID))
        XCTAssertTrue(make().schedules.isEmpty)
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(60), mode: .alarm, now: now))
        XCTAssertTrue(scheduler.cancelAll())
        XCTAssertTrue(make().pending.isEmpty)
    }

    func testCorruptStorePreservedAndWritesRefused() throws {
        let data = Data("corrupt".utf8)
        try data.write(to: file)
        let scheduler = make()
        XCTAssertNotNil(scheduler.persistenceError)
        XCTAssertFalse(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(60), mode: .timer, now: now))
        XCTAssertEqual(try Data(contentsOf: file), data)
    }

    func testPersistenceFailurePreventsArming() throws {
        let blocker = directory.appendingPathComponent("file")
        try Data().write(to: blocker)
        let scheduler = MacroScheduler(fileURL: blocker.appendingPathComponent("schedules.json"), now: now)
        XCTAssertFalse(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(60), mode: .timer, now: now))
        XCTAssertTrue(scheduler.pending.isEmpty)
        XCTAssertNotNil(scheduler.persistenceError)
    }
    func testConsumptionFailureNeverPostsInput() throws {
        let scheduler = make()
        scheduler.onRun = { _ in XCTFail("Must persist consumption before running") }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(1), mode: .timer, now: now))
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        scheduler.processDue(now: now.addingTimeInterval(1))
        XCTAssertEqual(scheduler.pending.count, 1)
        XCTAssertNotNil(scheduler.persistenceError)
    }

    func testEmergencyCancellationDisarmsEvenWhenDiskFails() throws {
        let scheduler = make()
        scheduler.onRun = { _ in XCTFail("Stop must disarm the process even when disk writes fail") }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(1), mode: .timer, now: now))
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        XCTAssertFalse(scheduler.cancelAll())
        try FileManager.default.removeItem(at: file)
        scheduler.resume(now: now)
        scheduler.processDue(now: now.addingTimeInterval(1))
        XCTAssertEqual(scheduler.pending.count, 1)
    }

    func testNewScheduleAfterFailedStopNeverRearmsCancelledRuns() throws {
        let scheduler = make()
        let newMacroID = UUID()
        var runs: [UUID] = []
        scheduler.onRun = { runs.append($0) }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(1), mode: .timer, now: now))
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        XCTAssertFalse(scheduler.cancelAll())
        XCTAssertFalse(scheduler.set(macroID: newMacroID, fireDate: now.addingTimeInterval(2), mode: .timer, now: now))
        scheduler.processDue(now: now.addingTimeInterval(1))
        XCTAssertTrue(runs.isEmpty)

        try FileManager.default.removeItem(at: file)
        XCTAssertTrue(scheduler.set(macroID: newMacroID, fireDate: now.addingTimeInterval(2), mode: .timer, now: now))
        XCTAssertEqual(make().pending.map(\.macroID), [newMacroID])
        scheduler.processDue(now: now.addingTimeInterval(2))
        scheduler.processDue(now: now.addingTimeInterval(3))
        XCTAssertEqual(runs, [newMacroID])
    }

    @MainActor
    func testLiveRunLoopTimerFires() async throws {
        let scheduler = MacroScheduler(fileURL: file)
        let fired = expectation(description: "Scheduled callback")
        scheduler.onRun = { _ in fired.fulfill() }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: Date().addingTimeInterval(0.1), mode: .timer))
        scheduler.start()
        await fulfillment(of: [fired], timeout: 3)
        XCTAssertEqual(scheduler.schedules.first?.status, .completed)
    }

    func testWakeDisarmsOverdueRunEvenWhenPersistenceFails() throws {
        let scheduler = make()
        scheduler.onRun = { _ in XCTFail("An overdue run must remain disarmed") }
        XCTAssertTrue(scheduler.set(macroID: macroID, fireDate: now.addingTimeInterval(1), mode: .timer, now: now))
        scheduler.suspend()
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        scheduler.resume(now: now.addingTimeInterval(2))
        XCTAssertEqual(scheduler.schedules.first?.status, .missed)
        try FileManager.default.removeItem(at: file)
        scheduler.processDue(now: now.addingTimeInterval(3))
        XCTAssertTrue(scheduler.pending.isEmpty)
    }

}
