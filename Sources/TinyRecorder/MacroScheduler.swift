import Foundation
import Combine

struct MacroSchedule: Codable, Identifiable, Equatable {
    enum Mode: String, Codable, CaseIterable { case timer, alarm }
    enum Status: String, Codable { case pending, completed, missed, blocked }

    var id = UUID()
    var macroID: UUID
    var fireDate: Date
    var mode: Mode
    var status: Status = .pending
    var detail: String? = nil
}

/// One local, one-time schedule per macro. Consume a run on disk BEFORE posting
/// input so a crash/relaunch cannot replay the same automation a second time.
final class MacroScheduler: ObservableObject {
    @Published private(set) var schedules: [MacroSchedule] = []
    @Published private(set) var persistenceError: String?
    var unavailableReason: ((UUID) -> String?)?
    var onRun: ((UUID) -> Void)?

    private let fileURL: URL
    private var loadedCleanly = true
    private var timer: Timer?
    private var suspended = false
    private var cancellationFailed = false

    var pending: [MacroSchedule] {
        schedules.filter { $0.status == .pending }.sorted { $0.fireDate < $1.fireDate }
    }

    static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TinyRecorder/schedules.json")
    }

    init(fileURL: URL = MacroScheduler.defaultFileURL, now: Date = Date()) {
        self.fileURL = fileURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                schedules = try JSONDecoder().decode([MacroSchedule].self, from: Data(contentsOf: fileURL))
                guard schedules.allSatisfy({ $0.fireDate.timeIntervalSinceReferenceDate.isFinite }),
                      Set(schedules.map(\.macroID)).count == schedules.count else {
                    throw CocoaError(.fileReadCorruptFile)
                }
            } catch {
                schedules = []
                loadedCleanly = false
                persistenceError = "Could not read schedules.json. The original file has been preserved."
            }
        }
        markOverdue(now: now, reason: "TinyTask was closed when this run was due. Reschedule to run it.")
    }

    deinit { timer?.invalidate() }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.processDue() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @discardableResult
    func set(macroID: UUID, fireDate: Date, mode: MacroSchedule.Mode, now: Date = Date()) -> Bool {
        guard fireDate.timeIntervalSinceReferenceDate.isFinite, fireDate > now else { return false }
        // After a failed Stop, an explicit new schedule may rearm the scheduler
        // only after the old pending runs have been durably removed.
        var updated = schedules.filter {
            $0.macroID != macroID && (!cancellationFailed || $0.status != .pending)
        }
        updated.append(MacroSchedule(macroID: macroID, fireDate: fireDate, mode: mode))
        guard commit(updated) else { return false }
        cancellationFailed = false
        return true
    }

    @discardableResult
    func remove(macroID: UUID) -> Bool {
        commit(schedules.filter { $0.macroID != macroID })
    }

    @discardableResult
    func cancelAll() -> Bool {
        let saved = commit(schedules.filter { $0.status != .pending })
        // Even if the disk is unavailable, Stop must disarm this process.
        cancellationFailed = !saved
        return saved
    }

    /// Waking never silently catches up on automation that was due during sleep.
    func suspend() { suspended = true }
    func resume(now: Date = Date()) {
        markOverdue(now: now, reason: "The Mac was asleep when this run was due. Reschedule to run it.")
        suspended = false
    }

    func processDue(now: Date = Date()) {
        guard !suspended, !cancellationFailed, loadedCleanly, let onRun else { return }
        for schedule in pending where schedule.fireDate <= now {
            var updated = schedules
            guard let index = updated.firstIndex(where: { $0.id == schedule.id }) else { continue }
            let reason: String?
            if now.timeIntervalSince(schedule.fireDate) > 5 {
                reason = "The scheduled time was missed. Reschedule to run it."
                updated[index].status = .missed
            } else {
                reason = unavailableReason?(schedule.macroID)
                updated[index].status = reason == nil ? .completed : .blocked
            }
            updated[index].detail = reason
            guard commit(updated) else { return }
            if reason == nil { onRun(schedule.macroID) }
        }
    }

    private func markOverdue(now: Date, reason: String) {
        var updated = schedules
        for index in updated.indices where updated[index].status == .pending && updated[index].fireDate <= now {
            updated[index].status = .missed
            updated[index].detail = reason
        }
        if updated != schedules && !commit(updated) {
            // Keep overdue runs disarmed in memory even if their missed status
            // cannot yet be written. A later successful write preserves it.
            schedules = updated
        }
    }

    private func commit(_ updated: [MacroSchedule]) -> Bool {
        guard loadedCleanly else { return false }
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            try JSONEncoder().encode(updated).write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
            schedules = updated
            persistenceError = nil
            return true
        } catch {
            persistenceError = "Could not save schedules. Check that Application Support is writable."
            return false
        }
    }
}
