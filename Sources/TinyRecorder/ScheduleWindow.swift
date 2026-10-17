import SwiftUI
import AppKit

final class ScheduleWindowController: NSWindowController {
    init(controller: MenuBarController, macroID: UUID?) {
        let view = ScheduleLibraryView(controller: controller, initialMacroID: macroID)
            .environmentObject(controller.library)
            .environmentObject(controller.scheduler)
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Schedule a Run"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 420, height: 480))
        window.contentMinSize = NSSize(width: 400, height: 420)
        window.isReleasedWhenClosed = false
        restoreFrameOrCenter(window, name: "TinyRecorder.Schedule.Compact")
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

private struct ScheduleLibraryView: View {
    let controller: MenuBarController
    let initialMacroID: UUID?
    @EnvironmentObject private var library: MacroLibrary

    var body: some View {
        ScheduleView(
            macros: library.macros,
            initialMacroID: initialMacroID,
            stopHotkey: controller.state.stopHotkey.name,
            onSchedule: controller.scheduleMacro
        )
    }
}

struct ScheduleView: View {
    let macros: [SavedMacro]
    let initialMacroID: UUID?
    let stopHotkey: String
    let onSchedule: (UUID, Date, MacroSchedule.Mode) -> Bool
    @EnvironmentObject private var scheduler: MacroScheduler
    @State private var macroID: UUID?
    @State private var mode: MacroSchedule.Mode = .timer
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var alarmDate = ScheduleView.alarmMinute(Date().addingTimeInterval(300))
    @State private var feedback = ""

    private var delay: TimeInterval { Double(hours * 3600 + minutes * 60 + seconds) }
    private var selectedMacro: SavedMacro? { macros.first { $0.id == macroID } }
    private var existing: MacroSchedule? { scheduler.schedules.first { $0.macroID == macroID } }
    private var valid: Bool {
        guard let selectedMacro, !selectedMacro.events.isEmpty else { return false }
        return mode == .timer ? delay > 0 : alarmDate > Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Schedule a run")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Run a saved recording once, later.")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                    composer
                    queue
                }
                .padding(14)
            }
            Divider()
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").foregroundStyle(.blue)
                    .help("Missed or busy runs stay here for rescheduling. Uses the macro’s current speed, repeats and chain.")
                    .accessibilityLabel("Missed or busy runs require rescheduling. Uses current speed, repeats and chain.")
                Text("Keep app running; Mac awake & unlocked. Stop: \(stopHotkey).")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.3))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { choose(initialMacroID ?? macros.first?.id) }
        .onChange(of: macroID) { feedback = "" }
        .onChange(of: mode) {
            if mode == .alarm { alarmDate = Self.alarmMinute(alarmDate) }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Recording", selection: $macroID) {
                Text("Choose a recording").tag(nil as UUID?)
                ForEach(macros) { macro in Text(macro.name).tag(Optional(macro.id)) }
            }
            .onChange(of: macroID) { loadExisting() }
            .disabled(macros.isEmpty)
            Picker("Schedule type", selection: $mode) {
                Label("After a delay", systemImage: "timer").tag(MacroSchedule.Mode.timer)
                Label("At a date & time", systemImage: "alarm").tag(MacroSchedule.Mode.alarm)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            if mode == .timer {
                HStack(spacing: 8) {
                    durationField("Hours", value: $hours, range: 0...99)
                    Text(":").font(.title2).foregroundStyle(.tertiary)
                    durationField("Minutes", value: $minutes, range: 0...59)
                    Text(":").font(.title2).foregroundStyle(.tertiary)
                    durationField("Seconds", value: $seconds, range: 0...59)
                }
                HStack(spacing: 8) {
                    ForEach([1, 5, 15, 30, 60], id: \.self) { value in
                        Button(value == 60 ? "1 hour" : "\(value) min") {
                            hours = value / 60; minutes = value % 60; seconds = 0
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                }
            } else {
                DatePicker("Run on", selection: Binding(
                    get: { alarmDate },
                    set: { alarmDate = Self.alarmMinute($0) }
                ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.field)
                    .padding(.vertical, 4)
                Text("\(TimeZone.current.localizedName(for: TimeZone.current.isDaylightSavingTime(for: alarmDate) ? .daylightSaving : .standard, locale: .current) ?? TimeZone.current.identifier) · one-time run")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        if mode == .timer && delay > 0 {
                            Text("Runs \(context.date.addingTimeInterval(delay).formatted(date: .abbreviated, time: .standard))")
                        } else if mode == .alarm {
                            Text(alarmDate > context.date ? "Runs \(alarmDate.formatted(date: .abbreviated, time: .shortened))" : "Choose a future date and time")
                        } else {
                            Text("Choose a delay greater than zero")
                        }
                    }
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    if !feedback.isEmpty { Text(feedback).font(.caption).foregroundStyle(.blue) }
                }
                Spacer(minLength: 8)
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Button(existing?.status == .pending ? "Update" : "Schedule") { save() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!valid)
                }
            }
            if let error = scheduler.persistenceError {
                Label(error, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.08)))
    }

    private func durationField(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 5) {
            Picker(title, selection: value) {
                ForEach(range, id: \.self) { number in Text(String(format: "%02d", number)).tag(number) }
            }
            .labelsHidden()
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .accessibilityLabel(title)
            Text(title.lowercased()).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var queue: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scheduled runs").font(.system(size: 12, weight: .semibold))
                Text("\(scheduler.pending.count) upcoming").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            if scheduler.schedules.isEmpty {
                Label("Your next run will appear here.", systemImage: "calendar.badge.clock")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 42)
            } else {
                ForEach(scheduler.schedules.sorted { lhs, rhs in
                    if (lhs.status == .pending) != (rhs.status == .pending) { return lhs.status == .pending }
                    return lhs.fireDate < rhs.fireDate
                }) { schedule in
                    queueRow(schedule)
                }
            }
        }
    }

    private func queueRow(_ schedule: MacroSchedule) -> some View {
        let macro = macros.first { $0.id == schedule.macroID }
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: schedule.status == .pending ? (schedule.mode == .timer ? "timer" : "alarm") : (schedule.status == .completed ? "checkmark.circle" : "exclamationmark.circle"))
                .font(.system(size: 17)).foregroundStyle(schedule.status == .pending ? Color.blue : .secondary)
                .frame(width: 24).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(macro?.name ?? "Recording removed").font(.system(size: 12, weight: .semibold)).lineLimit(1)
                Text(schedule.fireDate.formatted(date: .abbreviated, time: .standard))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                if schedule.status == .pending {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text("Starts in \(remaining(schedule.fireDate.timeIntervalSince(context.date)))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(.blue)
                    }
                } else {
                    Text(schedule.detail ?? "Started at the scheduled time")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if macro != nil {
                Button(schedule.status == .pending ? "Edit" : "Reschedule") { choose(schedule.macroID) }
                    .controlSize(.small)
            }
            Button { _ = scheduler.remove(macroID: schedule.macroID) } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help(schedule.status == .pending ? "Cancel scheduled run" : "Dismiss")
            .accessibilityLabel(schedule.status == .pending ? "Cancel schedule for \(macro?.name ?? "recording")" : "Dismiss schedule")
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }

    private func choose(_ id: UUID?) {
        macroID = id
        loadExisting()
    }

    private func loadExisting() {
        guard let existing else { return }
        mode = existing.mode
        alarmDate = Self.alarmMinute(existing.fireDate > Date() ? existing.fireDate : Date().addingTimeInterval(300))
        if existing.status == .pending && mode == .timer {
            let remaining = max(1, min(359999, Int(ceil(existing.fireDate.timeIntervalSinceNow))))
            hours = remaining / 3600; minutes = (remaining % 3600) / 60; seconds = remaining % 60
        }
    }

    /// The alarm picker displays minutes, so hidden seconds must never shift a run.
    static func alarmMinute(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .minute, for: date)?.start ?? date
    }

    private func save() {
        guard valid, let macroID else { return }
        let date = mode == .timer ? Date().addingTimeInterval(delay) : Self.alarmMinute(alarmDate)
        if onSchedule(macroID, date, mode) {
            feedback = "Scheduled. You can close this window."
        }
    }

    private func remaining(_ interval: TimeInterval) -> String {
        let total = max(0, Int(ceil(interval)))
        if total >= 86400 { return "\(total / 86400)d \((total % 86400) / 3600)h" }
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
