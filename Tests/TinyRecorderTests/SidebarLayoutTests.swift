import XCTest
import SwiftUI
import AppKit
@testable import TinyRecorder

final class SidebarLayoutTests: XCTestCase {
    private let filters: [LibraryFilter] = [.all, .favorites, .recent, .mostPlayed, .withHotkey]

    private func footerRows() -> [FooterRow] {
        [
            FooterRow(icon: "plus", label: "New macro",
                      rightAccessory: AnyView(KeyCapView(text: "⌘R", size: .sm)), action: {}),
            FooterRow(icon: "slider.horizontal.below.rectangle", label: "Open editor",
                      rightAccessory: nil, action: {}),
            FooterRow(icon: "gearshape", label: "Settings",
                      rightAccessory: AnyView(KeyCapView(text: "⌘,", size: .sm)), action: {}),
        ]
    }

    @MainActor
    func testFixedSidebarLabelsFitAtMinimumWidth() {
        let rowSpace = SidebarMetrics.minWidth - SidebarMetrics.rowInset * 2
        for item in filters {
            for selected in [false, true] {
                let row = NSHostingView(rootView: SidebarFilterRow(item: item, count: 888, selected: selected, action: {}))
                XCTAssertLessThanOrEqual(row.fittingSize.width, rowSpace, "\(item.label) truncates")
            }
        }
        let footerSpace = SidebarMetrics.minWidth - SidebarMetrics.footerInset * 2
        for footer in footerRows() {
            XCTAssertLessThanOrEqual(NSHostingView(rootView: footer).fittingSize.width, footerSpace,
                                     "\(footer.label) truncates")
        }
    }

    func testSidebarWidthClampKeepsDetailColumnUsable() {
        XCTAssertEqual(SidebarMetrics.clamped(100, totalWidth: 640), SidebarMetrics.minWidth)
        XCTAssertEqual(SidebarMetrics.clamped(250, totalWidth: 1000), 250)
        XCTAssertEqual(SidebarMetrics.clamped(900, totalWidth: 1000), SidebarMetrics.maxWidth)
        // Minimum window: the macro column keeps its minimum width.
        XCTAssertEqual(SidebarMetrics.clamped(900, totalWidth: 560), 560 - SidebarMetrics.minDetailWidth)
        // Narrower than min + detail: the sidebar never drops below its minimum.
        XCTAssertEqual(SidebarMetrics.clamped(900, totalWidth: 400), SidebarMetrics.minWidth)
    }

    @MainActor
    func testRendersResizableSidebar() async throws {
        let cases: [(String, CGFloat, CGFloat)] = [
            ("min", SidebarMetrics.minWidth, 560),
            ("default", SidebarMetrics.defaultWidth, 640),
            ("wide", 280, 900),
        ]
        let footers = footerRows()
        for (name, width, windowWidth) in cases {
            for dark in [false, true] {
                let view = ResizableSidebarLayout(sidebarWidth: .constant(Double(width))) {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(self.filters, id: \.self) { item in
                                SidebarFilterRow(item: item, count: item == .all ? 128 : 12,
                                                 selected: item == .mostPlayed, action: {})
                            }
                            SidebarFilterRow(item: .tag("client-onboarding-weekly"), count: 3,
                                             selected: false, action: {})
                        }
                        .padding(.horizontal, SidebarMetrics.rowInset)
                        .padding(.top, 12)
                        Spacer()
                        Divider().opacity(0.45)
                        VStack(spacing: 0) {
                            ForEach(footers.indices, id: \.self) { footers[$0] }
                        }
                        .padding(.horizontal, SidebarMetrics.footerInset)
                        .padding(.vertical, 5)
                    }
                } detail: {
                    Color.primary.opacity(0.03)
                }
                .frame(width: windowWidth, height: 360)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, dark ? .dark : .light)
                let host = NSHostingView(rootView: view)
                host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                host.frame = NSRect(x: 0, y: 0, width: windowWidth, height: 360)
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(nanoseconds: 100_000_000)
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                if let output = ProcessInfo.processInfo.environment["TINYRECORDER_LAYOUT_OUTPUT"] {
                    let url = URL(fileURLWithPath: output)
                        .appendingPathComponent("sidebar-\(name)-\(dark ? "dark" : "light").png")
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: url)
                }
            }
        }
    }
}
