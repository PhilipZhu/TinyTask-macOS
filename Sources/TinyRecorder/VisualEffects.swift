import SwiftUI
import AppKit

// MARK: - Brand design tokens

enum Brand {
    // Signature red — richer, more confident (rec scale)
    static let red400 = Color(red: 0.961, green: 0.329, blue: 0.329) // #f55454
    static let red500 = Color(red: 0.906, green: 0.169, blue: 0.169) // #e72b2b
    static let red600 = Color(red: 0.800, green: 0.122, blue: 0.122) // #cc1f1f
    static let red700 = Color(red: 0.678, green: 0.094, blue: 0.094) // #ad1818

    static let redTop    = red400
    static let redBottom = red600

    /// The signature record-button gradient (#f55454 → #cc1f1f).
    static var redGradient: LinearGradient {
        LinearGradient(colors: [red400, red600], startPoint: .top, endPoint: .bottom)
    }

    /// A flat tint approximating the brand red, for tinting Liquid Glass.
    static let redTint = Color(red: 0.88, green: 0.22, blue: 0.22)

    // Signal accents — modern, vibrant but harmonious (oklch → sRGB approximations)
    static let sigBlue   = Color(red: 0.22, green: 0.48, blue: 0.96)
    static let sigGreen  = Color(red: 0.16, green: 0.72, blue: 0.45)
    static let sigAmber  = Color(red: 0.95, green: 0.68, blue: 0.20)
    static let sigViolet = Color(red: 0.58, green: 0.38, blue: 0.95)
    static let sigTeal   = Color(red: 0.22, green: 0.72, blue: 0.80)
    static let sigPink   = Color(red: 0.95, green: 0.36, blue: 0.62)

    /// Named accent (from `SavedMacro.accent`) → a vibrant signal color.
    static func accent(_ name: String?) -> Color {
        switch name?.lowercased() {
        case "red":    return red500
        case "orange", "amber": return sigAmber
        case "yellow": return sigAmber
        case "green":  return sigGreen
        case "teal":   return sigTeal
        case "blue":   return sigBlue
        case "indigo", "violet", "purple": return sigViolet
        case "pink":   return sigPink
        case "gray", "grey": return Color(white: 0.55)
        default:       return red500
        }
    }

    /// Event-kind → signal color (the design's waveform legend).
    static func eventColor(_ kind: RecordedEvent.Kind, dark: Bool = true) -> Color {
        switch kind {
        case .leftMouseDown, .leftMouseUp:       return sigGreen          // click
        case .rightMouseDown, .rightMouseUp:     return sigAmber          // right-click
        case .otherMouseDown, .otherMouseUp:     return sigAmber
        case .keyDown, .keyUp, .flagsChanged:    return sigBlue           // key
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
                                                 return sigViolet          // drag
        case .scrollWheel:                       return sigTeal           // scroll
        case .mouseMoved:                        return Color.primary.opacity(0.22) // move
        }
    }

    /// Whether an event kind is an "impact" (taller tick) vs a move.
    static func isImpact(_ kind: RecordedEvent.Kind) -> Bool {
        switch kind {
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return false
        default:
            return true
        }
    }

    /// The one spring used for state changes app-wide — consistent motion.
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.85)

    /// Builds a configured Liquid Glass variant. macOS 26+ only.
    @available(macOS 26.0, *)
    static func glass(tint: Color? = nil, interactive: Bool = false) -> Glass {
        var g: Glass = .regular
        if let tint { g = g.tint(tint) }
        if interactive { g = g.interactive() }
        return g
    }
}

// MARK: - Liquid Glass (macOS 26+) with graceful fallback

extension View {
    /// Prominent, tinted capsule control: interactive tinted Liquid Glass on
    /// macOS 26+, a tinted gradient capsule on earlier systems. Reserved for the
    /// app's primary actions (e.g. the Record button) — glass belongs to the
    /// floating control layer, used sparingly.
    @ViewBuilder
    func prominentGlassCapsule(tint: Color, gradientFallback: [Color]? = nil) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(Brand.glass(tint: tint, interactive: true), in: Capsule(style: .continuous))
        } else {
            background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(
                        colors: gradientFallback ?? [tint.opacity(0.95), tint.opacity(0.78)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                    )
                    .shadow(color: tint.opacity(0.30), radius: 3, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Wordmark

/// The "tiny Task" wordmark — italic serif "tiny" + semibold "Task".
struct Wordmark: View {
    var size: CGFloat = 13
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.04) {
            Text("tiny")
                .font(.system(size: size * 1.25, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
            Text("Task")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.primary)
                .tracking(-0.3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("TinyTask")
    }
}

// MARK: - Material backgrounds (NSVisualEffectView)

/// Wraps NSVisualEffectView so SwiftUI views get real macOS vibrancy/translucency.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .followsWindowActiveState
    var isEmphasized: Bool = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = state
        v.isEmphasized = isEmphasized
        v.autoresizingMask = [.width, .height]
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.isEmphasized = isEmphasized
    }
}

// MARK: - Card styles

extension View {
    /// Subtle layered card on top of vibrancy — adapts to light/dark.
    func cardSurface(cornerRadius: CGFloat = 12) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius))
    }

    /// Flat hover feedback shared by the app's interactive surfaces: a light
    /// shade over the control's shape, with no movement, tilt or shadow change.
    func hoverShade(cornerRadius: CGFloat = 8) -> some View {
        modifier(HoverShade(cornerRadius: cornerRadius))
    }
}

private struct CardSurface: ViewModifier {
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Hover shade

private struct HoverShade: ViewModifier {
    let cornerRadius: CGFloat

    @Environment(\.isEnabled) private var isEnabled
    @State private var hovered = false

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(hovered && isEnabled ? 0.07 : 0))
                    .animation(.easeOut(duration: 0.12), value: hovered)
                    .allowsHitTesting(false)
            }
            .onHover { hovered = $0 }
    }
}

// MARK: - Press response (paired with hoverShade)

struct HoverPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Key-cap chip (chiseled, multi-size, glass variant)

struct KeyCapView: View {
    enum Size { case sm, md, lg }
    enum Variant { case standard, glass }

    let text: String
    var size: Size = .md
    var variant: Variant = .standard
    @Environment(\.colorScheme) private var scheme

    private var height: CGFloat { size == .sm ? 18 : (size == .lg ? 28 : 22) }
    private var minW: CGFloat   { size == .sm ? 18 : (size == .lg ? 30 : 22) }
    private var font: CGFloat   { size == .sm ? 10 : (size == .lg ? 13 : 11) }
    private var radius: CGFloat { size == .sm ? 4 : 6 }

    var body: some View {
        Text(text)
            .font(.system(size: font, weight: .semibold, design: .monospaced))
            .foregroundStyle(variant == .glass ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(minWidth: minW, minHeight: height)
            .padding(.horizontal, size == .lg ? 8 : (size == .sm ? 5 : 6))
            .background(background)
            .accessibilityLabel("Shortcut \(text)")
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if variant == .glass {
            shape.fill(Color.white.opacity(0.16))
                .overlay(shape.strokeBorder(Color.white.opacity(0.24), lineWidth: 0.5))
                .overlay(shape.fill(LinearGradient(
                    colors: [Color.white.opacity(0.20), .clear],
                    startPoint: .top, endPoint: .center)))
        } else {
            let isDark = scheme == .dark
            shape
                .fill(LinearGradient(
                    colors: isDark
                        ? [Color(red: 0.165, green: 0.176, blue: 0.212), Color(red: 0.122, green: 0.133, blue: 0.161)]
                        : [.white, Color(red: 0.933, green: 0.941, blue: 0.957)],
                    startPoint: .top, endPoint: .bottom))
                .overlay(shape.strokeBorder(
                    isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.20), lineWidth: 0.5))
                .overlay(   // top inner highlight
                    shape.fill(LinearGradient(
                        colors: [Color.white.opacity(isDark ? 0.10 : 0.80), .clear],
                        startPoint: .top, endPoint: .center)).blendMode(.plusLighter).opacity(0.6))
                .shadow(color: .black.opacity(isDark ? 0.40 : 0.10), radius: 0, x: 0, y: 1)
        }
    }
}

// MARK: - Pulsing record dot

struct RecDot: View {
    var size: CGFloat = 8
    var color: Color = Brand.red500
    var glassWhite: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        let c = glassWhite ? Color.white : color
        ZStack {
            Circle()
                .stroke(c.opacity(0.55), lineWidth: 1.5)
                .scaleEffect(!reduceMotion && pulse ? 2.2 : 1.0)
                .opacity(reduceMotion ? 0.45 : (pulse ? 0 : 0.8))
            Circle()
                .fill(c)
                .shadow(color: c.opacity(0.6), radius: size * 0.6)
        }
        .frame(width: size, height: size)
        .onAppear { pulse = !reduceMotion }
        .onChange(of: reduceMotion) { _, reduced in pulse = !reduced }
        .animation(
            reduceMotion ? nil : .easeOut(duration: 1.6).repeatForever(autoreverses: false),
            value: pulse
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Brand mark

/// Use the shipped multiresolution icon so Dock and in-app branding match.
struct BrandMark: View {
    var size: CGFloat = 30
    private static let icon = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
        .flatMap { NSImage(contentsOf: $0) }

    var body: some View {
        Group {
            if let icon = Self.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
            } else {
                // Bundle-less SwiftPM previews have no app resource directory.
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .foregroundStyle(Brand.red400)
                    .padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
