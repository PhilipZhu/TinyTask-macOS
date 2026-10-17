# TinyTask

A free **macro recorder for macOS**. Record any sequence of mouse clicks, drags, scrolls and keystrokes, then replay it on demand. Lives in the Dock and the menu bar.

macOS doesn't ship a built-in macro recorder — TinyTask is one. No subscription, no account, no telemetry, no nag.

## Build and install

Requires Xcode 26 or newer and macOS 14 or newer. Clone this fork, then build and install:

```bash
git clone https://github.com/PhilipZhu/TinyTask-macOS.git
cd TinyTask-macOS
./build.sh
open /Applications/TinyTask.app
```

Quit TinyTask before replacing an existing installation. The app walks you through permissions on first launch. This fork is distributed as source; the original project is [Aaru1801/TinyTask-macOS](https://github.com/Aaru1801/TinyTask-macOS).

## Updates in this fork

- Schedule a saved recording after a delay or at a date and time, with a queue for editing, cancellation and missed runs.
- Compact windows, flat hover feedback and a resizable library sidebar.
- TinyTask app naming and a pointer-clicking-button icon.
- Shared permission checks, immediate rechecking after Settings and help for stale app approvals.

The sections below describe features inherited from the original project.

## What's in 1.9 — "Quick Run & Live Activity"

- ⚡ **Quick Run** — press **⌘K** for a Spotlight-style command palette with fuzzy macro search, arrow-key navigation, shortcuts, and instant access to recording, import, editing, and settings.
- 📊 **Finder-style Activity Center** — live recording/countdown state plus playback progress, loop and event counts, percentage, and time remaining in one compact control surface.
- 🧊 **Compact native workspace** — a tighter utility-sized library, dimensional hover/press motion, active-card playback rails, refined empty states, and full Reduce Motion support.
- 🟢 **Progress everywhere** — the playing card, menu-bar item, Dock badge, and Activity Center stay synchronized with percentage or continuous-loop status.
- 🛡️ **Safer playback** — TinyTask clears its own windows before synthetic input, cancels exposed panels, releases held keys/buttons on every exit path, and stops playback before reopening interactive UI.
- ⚙️ **Faster, safer internals** — non-blocking playback telemetry, coalesced private library saves, hardened imports, bounded loop counts, and owner-only macro files.

## What's in 1.7 — "Design system"

Introduced a cohesive native design system across every surface:
- 🎨 **Signal palette** — events are colored by kind everywhere (key=blue, click=green, scroll=teal, drag=violet, right-click=amber, move=gray), turning every waveform into something you can read at a glance.
- 🔤 **Refined typography & numerics** — italic-serif "tiny" wordmark, monospaced timestamps/counters, tracked small-caps section labels.
- ⌨️ **Chiseled keycaps** (with a glass variant on the HUD) and a **pulsing record dot**.
- 🟥 **Reel-and-smile brand mark** rendered natively in the original 1.7 release. This fork now uses a mouse-clicking-a-button icon in `Assets/TinyTaskIcon.png`.
- 📋 **Library** — brand row + status, full-width record button with the record-hotkey keycap, ⌘F search, restrained accent on cards.
- 🎬 **Recording HUD** — inky Liquid Glass over the live desktop: gradient mono timer, event-track panel with time ruler, a 4-stat grid (clicks/keys/scroll/drag), and Discard/Stop with keycap chords.

## What's in 1.6 — "Liquid Glass"

- 🧊 **Liquid Glass** (macOS 26+) — applied the Apple way: the floating recording HUD and the pre-record countdown are real `NSGlassEffectView` glass that refracts the desktop behind them, and the Record button is tinted prominent glass. The content layer (cards, sidebar, lists) stays opaque per Apple's guidance, so nothing looks muddy. Falls back to standard vibrancy on macOS 13–15.
- 🎨 **Restrained accent** — selected/current cards use a thin accent border + faint tint instead of a heavy colored fill.
- 🔁 **TinyTask + text import** — open `.rec` (TinyTask) and `.txt`/`.trm` macros, convert from the command line (see below).

## What's in 1.3 — "The Library Update"

- 🚀 **Full Dock app** — proper window, top-of-screen menu bar with File / Edit / Macro / Window / Help, real keyboard shortcuts, frame autosaves between launches
- 👋 **Onboarding wizard** — a four-step welcome flow that grants permissions and explains hotkeys before you record your first macro
- ⌨️ **Per-macro hotkeys** — assign any F-key to any macro and trigger it from anywhere, no need to bring the app forward
- ⭐ **Favorites + library filters** — sidebar with All / Favorites / Recent / Most Played / Has Hotkey / per-tag
- 🏷 **Tags** — organize macros across projects
- 🎨 **Custom icons** — pick an SF Symbol for any macro to scan your library at a glance
- 📊 **Stats** — every card shows play count and last-played; sidebar shows total plays & time replayed
- 🔗 **Macro chains** — when one macro finishes, automatically play another
- ⏳ **Pre-record countdown** — a big floating "3 · 2 · 1" overlay so you have time to switch to the right window
- 🔔 **Dock badge** — pulsing red dot while recording, live percentage or ∞ while playing
- 🔊 **Sound feedback** — optional subtle audio cues on record / play / stop (off by default)
- ✏️ **Editor: insert wait** — add a precise pause anywhere in the timeline
- 🎬 **Floating recording HUD** — live timer, event counter, click/key/scroll breakdown, mini live waveform
- 🎛 **Macro editor** — timeline with color-coded events, drag-to-select range, per-event time/X/Y/key inspector, time-stretch, trim before/after, bulk shift, insert wait
- 🔁 **Per-macro repeat** — each macro stores its own loop count: 1× / N× / **∞ continuous**
- ⏩ **Speed control** — playback at 0.5× / 1× / 2× / 4×
- 📤 **Export** — write any macro out as a self-running `.command` script or as `.tinyrec` JSON
- 📥 **Import** — `.tinyrec` files open natively (Finder double-click, drag onto the dock, File → Import)
- 🌗 **Adaptive light + dark** — system materials, vibrancy, hover states, springy animations
- 🔒 **Native** — Carbon hotkeys + `CGEventTap`, no Electron, no kernel extensions

## First launch

The welcome wizard requests access under **System Settings → Privacy & Security**:

- **Accessibility** enables recording and playback. A separate Input Monitoring grant is unnecessary when Accessibility is available.
- **Input Monitoring** can enable recording alone, without playback.

TinyTask checks the current process's access again when you return from Settings and before recording or playback. **Settings → Permissions** offers **Recheck Access** and **Already enabled? Help…**, which shows the exact running app path.

### If macOS shows access enabled but TinyTask still reports it missing

1. Quit all TinyTask/TinyRecorder copies with **⌘Q**.
2. Run `./build.sh`, then open `/Applications/TinyTask.app`. Use that same installed copy consistently.
3. In **Privacy & Security → Accessibility**, remove a stale TinyTask/TinyRecorder entry with **−**, then add `/Applications/TinyTask.app` with **+** and enable it.
4. Quit and reopen TinyTask after changing access. Use **Recheck Access**.
5. For recording without Accessibility, follow the same steps under **Input Monitoring**.

The build refuses to replace a running installation. Launching a second copy now identifies the running copy instead of silently redirecting to an older build. Existing macros, schedules and preferences are preserved. No privacy settings are changed automatically.

## Usage

The library opens at 640×430 points and can shrink to 560×360. Scheduling opens at 420×480; the menu-bar popover is 360×440. Windows remain resizable where appropriate; compact cards keep playback, scheduling, repeats, editing and the full action menu available.

Click the Dock icon (or menu-bar icon) to open the library:

1. Press **Record** in the header (or **F6**, or **⌘R**). A 3-second countdown appears, then a floating HUD takes over.
2. Run through whatever sequence you want to capture.
3. Press **F6** again or click **Stop** in the HUD. The macro auto-saves into the library.
4. Hit any card's **▶ Play** button (or press **F8**) to replay it.
5. Click **Schedule** on the saved recording to run it later, or open **Macro → Schedule Run…** (**⇧⌘S**). Choose **After a delay** (hours/minutes/seconds) or **At a date & time**.
6. Click **✎ Edit** on a card for the timeline editor — scrub, trim, time-stretch, insert waits, edit individual events.

Each card has small chips for hotkey, loop count, favorite ★, and a **⋯** menu for Rename, Tag, Duplicate, Export, Delete. Cmd-click cards to multi-select for bulk operations. Drag a card onto another to reorder.

## Scheduling recordings

Stopping a recording returns you to the library with a **Schedule run…** action. You can also schedule any saved recording from its card, the toolbar, or **⇧⌘S**.

- **After a delay:** set hours, minutes and seconds, or use a quick preset.
- **At a date & time:** choose a future date and local time for a one-time alarm.
- **Scheduled runs:** inspect the countdown, edit an upcoming run, cancel it, or reschedule a missed/blocked run. A recording has one schedule; updating replaces it.

Keep TinyTask running and your Mac awake and unlocked. Closing the library window is fine; quitting the app prevents runs. Pending schedules survive relaunch, but overdue runs require explicit rescheduling. Sleeping, locking, missing Accessibility permission, an open dialog, or another recording/playback prevents a run; the reason stays in the schedule window. Runs use the recording’s current events, speed, repeats and chain, so later edits apply. Exporting, importing or duplicating a recording does not copy its schedule.

**F7** (or your configured Stop hotkey) stops playback/recording and cancels all pending schedules. The normal Stop playback button only stops the active playback. Schedules are stored locally in `~/Library/Application Support/TinyRecorder/schedules.json`.

## Hotkeys

| Action | Default | Notes |
| --- | --- | --- |
| Record / Stop recording | **F6** | toggle |
| Stop everything | **F7** | aborts recording or playback |
| Play current macro | **F8** | uses the macro's own loop count |
| Schedule Run | **⇧⌘S** | timer or date/time alarm |
| Quick Run | **⌘K** | fuzzy macro and command palette |
| Search library | **⌘F** | focuses the library search field |
| New recording | **⌘R** | from menu / popover |
| Play | **⌘P** | menu shortcut |
| Stop | **⌘.** | menu shortcut |
| Import macro | **⌘O** | from a `.tinyrec` file |
| Export current | **⌘E** | as a `.command` script |
| Settings | **⌘,** | |
| Library window | **⌘0** | bring to front |

Configurable in **Preferences → Hotkeys**. Any saved macro can also have its own per-macro F-key assigned via the card's "⋯ → Assign Hotkey" — that hotkey will play that specific macro from any app.

## File format

`.tinyrec` is plain JSON, importable via Finder double-click, drag-onto-dock, or **File → Import**:

```json
{
  "version": 3,
  "name": "Slack daily standup",
  "createdAt": 766094400,
  "modifiedAt": 766094412,
  "loops": 1,
  "speed": 1.0,
  "icon": "wave.3.right",
  "tags": ["work", "morning"],
  "favorite": false,
  "hotkey": { "keyCode": 97, "name": "F6" },
  "playCount": 12,
  "lastPlayedAt": 766094412,
  "totalRunTime": 134.7,
  "notes": "",
  "chainTo": null,
  "events": [
    { "kind": 5, "time": 0.012, "x": 412.0, "y": 188.0, "keyCode": 0,
      "flags": 256, "mouseButton": 0, "clickCount": 0,
      "scrollDeltaY": 0, "scrollDeltaX": 0 }
  ]
}
```

TinyTask retains the original bundle identifier and data directories so existing settings, macros and schedules carry over.

The library lives at `~/Library/Application Support/TinyRecorder/library.json`.

## Importing & converting (TinyTask + text)

TinyTask reads three macro formats — drag any onto the window, double-click in Finder, use **File → Import**, or the command line:

- **`.tinyrec`** — native (full metadata).
- **`.rec`** — **TinyTask** macros (the Windows recorder). TinyTask decodes TinyTask's `EVENTMSG` records and translates Windows virtual-key codes to macOS keycodes automatically. Mouse moves/clicks and standard keystrokes convert reliably; mouse-wheel and non-US layouts are best-effort. The importer reports how many records it parsed vs. skipped.
- **`.txt` / `.trm`** — a simple, hand-editable plain-text format ("TRM"). Export any macro to it via the card menu → **Export → As Text…** or **File → Export as Text…** (⇧⌘E), edit it in any editor, and re-import.

### Text macro format (TRM)

One event per line, leading verb, whitespace-separated. `#` comments and blank lines ignored. `@<seconds>` is an absolute timestamp; `WAIT ms` inserts a delay.

```
TINYRECORDER 1
# move, click, type a Cmd+Space, scroll
@0.000  MOVE 640 400
@0.100  DOWN 640 400 L
@0.160  UP 640 400 L
@0.300  FLAGS CMD 0x100000
@0.310  KEYDOWN SPACE +CMD
@0.380  KEYUP SPACE +CMD
@0.390  FLAGS CMD 0x0
@0.500  KEYDOWN A
@0.530  KEYUP A
@0.700  SCROLL -3 0
```

Verbs: `MOVE x y`, `DRAG x y BTN`, `DOWN/UP x y BTN [clicks=N]` (BTN = `L`/`R`/`M`), `SCROLL dy [dx]`, `KEYDOWN/KEYUP <key> [+MODS]`, `FLAGS <key> <maskhex>`, `WAIT ms`. Keys are symbolic names (`A`, `SPACE`, `F1`, `LEFT`, `CMD`…) or `#<keycode>` for anything unnamed.

### Command-line converter

```bash
# Convert a Windows TinyTask file to a native macro (or to text):
TinyTask.app/Contents/MacOS/TinyTask --convert macro.rec macro.tinyrec
TinyTask.app/Contents/MacOS/TinyTask --convert macro.rec macro.txt
```

The output format is chosen by the output file's extension (`.tinyrec`/`.json` or `.txt`/`.trm`).

## Development

Build with `./build.sh` — it compiles the SwiftPM package, assembles `TinyTask.app`, stamps the build number from git, and signs with an available development identity (or ad-hoc signing). Sources live in `Sources/TinyRecorder/`.

The existing Xcode project and scheme are named `TinyRecorder`; their app output is `TinyTask.app`.

Run scheduler regression tests with `swift test`. To build a local app without replacing an installed copy, use `TINYTASK_INSTALL_DIR="$PWD/.build/local" ./build.sh`.

Requires the macOS 26 SDK (Xcode 26+) to compile the Liquid Glass layer; the app itself runs on macOS 14 or newer, with standard vibrancy on macOS 14–15. The app must **not** be sandboxed — `CGEventTap` recording and `CGEvent` posting require it off.

## Architecture

| File | Responsibility |
| --- | --- |
| `main.swift` | Entry point + CLI playback dispatch |
| `AppDelegate.swift` | Activation policy, top-of-screen menu, window lifecycle |
| `MainWindowController.swift` | Dockable library window |
| `MenuBarController.swift` | Status item, popover, library glue, hotkey registration |
| `MacroLibrary.swift` | Persistent library + filters + statistics |
| `Recorder.swift` | Live capture via `CGEvent.tapCreate(.cgSessionEventTap)` |
| `Player.swift` | Playback via `CGEvent.post`, loops + speed |
| `HotkeyManager.swift` | Global hotkeys via Carbon `RegisterEventHotKey` |
| `RecordingHUD.swift` | Floating HUD shown during recording |
| `CountdownOverlay.swift` | Pre-record 3-2-1 overlay |
| `WelcomeWindow.swift` | Onboarding wizard |
| `MacroEditor.swift` | Timeline + table + inspector editor |
| `PopoverContentView.swift` | Library UI (popover & main window) |
| `MacroScheduler.swift` | Persistent one-time schedules, conflict/missed-run handling |
| `ScheduleWindow.swift` | Timer/alarm composer and schedule queue |
| `ActivityCenterView.swift` | Live recording/countdown/playback progress surface |
| `QuickRunPalette.swift` | ⌘K fuzzy macro and command launcher |
| `SoundController.swift` | Optional audio feedback |
| `VisualEffects.swift` | Materials, hover styles, brand mark, key-cap chip |
| `AppState.swift` | UserDefaults-backed settings + permission watcher |
| `RecordedEvent.swift` | Codable event model |

## Known limits

- **Screen-coordinate based.** Macros replay the exact pixel positions they were recorded at, so resizing or moving target windows between record and play will misfire.
- **Hardened input paths.** A few apps (some banking apps, secure password fields) reject synthesized input. That's by design at the OS layer.
- **Reserved shortcuts.** Globally-reserved system shortcuts like ⌘Space can't be rebound as TinyTask hotkeys.

## License

[MIT](LICENSE) — © 2026 Aarav Bhargava.
