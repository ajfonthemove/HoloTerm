import AppKit
import SwiftUI
import Combine
import SwiftTerm
// `Color` typealias for SwiftUI.Color is declared in GradientBackdrop.swift.

// MARK: - App-wide preferences

final class AppState: ObservableObject {
    @Published var themeId: String { didSet { UserDefaults.standard.set(themeId, forKey: "themeId") } }

    var theme: Theme { Theme.find(id: themeId) }

    init() {
        self.themeId = UserDefaults.standard.string(forKey: "themeId") ?? Theme.default.id
    }
}

// MARK: - Glass settings (ported from LiquidGlassMail GlassAppearance)

final class GlassSettings: ObservableObject {
    @Published var enabled: Bool            { didSet { d.set(enabled, forKey: "glass.enabled") } }
    @Published var transparency: Double     { didSet { d.set(transparency, forKey: "glass.transparency") } }
    @Published var blurIntensity: Double    { didSet { d.set(blurIntensity, forKey: "glass.blurIntensity") } }
    @Published var tintStrength: Double     { didSet { d.set(tintStrength, forKey: "glass.tintStrength") } }
    @Published var backgroundVisibility: Double { didSet { d.set(backgroundVisibility, forKey: "glass.backgroundVisibility") } }
    @Published var tintColorHex: String     { didSet { d.set(tintColorHex, forKey: "glass.tintColorHex") } }

    // Text colour overrides.
    @Published var useThemeText: Bool       { didSet { d.set(useThemeText, forKey: "text.useTheme") } }
    @Published var textColorHex: String     { didSet { d.set(textColorHex, forKey: "text.colorHex") } }

    // Font.
    @Published var fontName: String         { didSet { d.set(fontName, forKey: "font.name") } }
    @Published var fontSize: Double         { didSet { d.set(fontSize, forKey: "font.size") } }

    private let d = UserDefaults.standard

    /// All font families available on this system.
    static let availableFonts: [String] = {
        NSFontManager.shared.availableFontFamilies.sorted()
    }()

    init() {
        self.enabled             = d.object(forKey: "glass.enabled")             as? Bool   ?? true
        self.transparency        = d.object(forKey: "glass.transparency")        as? Double ?? 0.72
        self.blurIntensity       = d.object(forKey: "glass.blurIntensity")       as? Double ?? 0.68
        self.tintStrength        = d.object(forKey: "glass.tintStrength")        as? Double ?? 0.14
        self.backgroundVisibility = d.object(forKey: "glass.backgroundVisibility") as? Double ?? 0.96
        self.tintColorHex        = d.string(forKey: "glass.tintColorHex")               ?? "#878787"
        self.useThemeText        = d.object(forKey: "text.useTheme")             as? Bool   ?? true
        self.textColorHex        = d.string(forKey: "text.colorHex")                    ?? "#f8f8f2"
        self.fontName            = d.string(forKey: "font.name")                        ?? "SF Mono"
        self.fontSize            = d.object(forKey: "font.size")                 as? Double ?? 14
    }

    /// Build a GlassAppearance struct (drives the multi-layer backdrop).
    var appearance: GlassAppearance {
        GlassAppearance(
            transparency: transparency,
            blurIntensity: blurIntensity,
            tintStrength: tintStrength,
            backgroundVisibility: backgroundVisibility,
            tintColor: Color(hex: tintColorHex)
        )
    }

    /// The effective terminal foreground as NSColor (for SwiftTerm).
    func effectiveTextColor(for theme: Theme) -> NSColor {
        let hex = useThemeText ? theme.foreground : textColorHex
        return NSColor(hex: hex)
    }

    /// The effective text colour as SwiftUI Color (for header / tab text).
    func effectiveTextSwiftUIColor(for theme: Theme) -> Color {
        let hex = useThemeText ? theme.foreground : textColorHex
        return Color(hex: hex)
    }
}

// MARK: - Tabs

final class TabsModel: ObservableObject {
    struct Tab: Identifiable, Equatable {
        let id: UUID
        var name: String
        let terminal: LocalProcessTerminalView

        static func == (lhs: Tab, rhs: Tab) -> Bool { lhs.id == rhs.id }
    }

    @Published var tabs: [Tab] = []
    @Published var activeId: UUID? = nil

    /// Inactive tabs that have received output since the user last viewed them.
    @Published var activityTabs: Set<UUID> = []

    func add(_ tab: Tab) {
        tabs.append(tab)
        activeId = tab.id
        activityTabs.remove(tab.id)
    }

    func close(_ id: UUID) {
        guard tabs.count > 1, let i = tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasActive = activeId == id
        let term = tabs[i].terminal
        term.processDelegate = nil
        term.terminate()
        tabs.remove(at: i)
        activityTabs.remove(id)
        if wasActive {
            activeId = tabs[min(i, tabs.count - 1)].id
        }
    }

    func select(_ id: UUID) {
        activeId = id
        activityTabs.remove(id)
    }

    func selectIndex(_ i: Int) {
        guard i >= 0, i < tabs.count else { return }
        select(tabs[i].id)
    }

    func cycle(_ delta: Int) {
        guard let id = activeId,
              let i = tabs.firstIndex(where: { $0.id == id }) else { return }
        let next = (i + delta + tabs.count) % tabs.count
        select(tabs[next].id)
    }

    func rename(_ id: UUID, to name: String) {
        guard let i = tabs.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { tabs[i].name = trimmed }
    }

    func markActivity(for id: UUID) {
        if id != activeId { activityTabs.insert(id) }
    }
}
