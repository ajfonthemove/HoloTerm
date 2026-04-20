import SwiftUI
import AppKit
import SwiftTerm
// `Color` typealias for SwiftUI.Color is declared in GradientBackdrop.swift.

// MARK: - Root content

struct ContentView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var glass: GlassSettings
    @ObservedObject var tabs: TabsModel
    let onNewTab: () -> Void

    var body: some View {
        ZStack {
            // Multi-layer glass backdrop (ported from LiquidGlassMail).
            // Contains its own NSVisualEffectView + gaussian wash + glows.
            if glass.enabled {
                GradientBackdrop(appearance: glass.appearance)
            } else {
                Rectangle().fill(Color.black)
                    .ignoresSafeArea()
            }

            Rectangle()
                .fill(Color.black.opacity(0.04))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(appState: appState, glass: glass, tabs: tabs, onNewTab: onNewTab)
                    .frame(height: 38)
                    .foregroundColor(glass.effectiveTextSwiftUIColor(for: appState.theme))

                TerminalArea(tabs: tabs)
            }
        }
    }
}

// MARK: - Header (tabs + theme picker + settings button)

struct HeaderView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var glass: GlassSettings
    @ObservedObject var tabs: TabsModel
    let onNewTab: () -> Void

    @State private var showSettings = false
    @State private var renamingId: UUID? = nil
    @State private var renameText = ""

    var body: some View {
        let headerTextColor = glass.effectiveTextSwiftUIColor(for: appState.theme)

        HStack(spacing: 4) {
            // Reserve space for traffic lights.
            Spacer().frame(width: 70)

            // Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs.tabs) { tab in
                        tabButton(tab)
                    }
                    Button(action: onNewTab) {
                        Image(systemName: "plus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(HeaderButtonStyle(textColor: headerTextColor))
                }
                .padding(.horizontal, 4)
            }

            Spacer(minLength: 0)

            // Settings button
            Button { showSettings.toggle() } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(HeaderButtonStyle(active: glass.enabled, textColor: headerTextColor))
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                SettingsView(glass: glass, theme: appState.theme)
                    .frame(width: 280)
                    .onAppear {
                        // macOS dims popover windows when the parent loses
                        // focus. Find the popover's NSWindow and disable that.
                        DispatchQueue.main.async {
                            for w in NSApp.windows where w.className.contains("Popover") {
                                w.animationBehavior = .none
                                w.isOpaque = false
                                w.alphaValue = 1
                                // Prevent the window from fading on deactivation.
                                NotificationCenter.default.addObserver(
                                    forName: NSWindow.didResignKeyNotification,
                                    object: w, queue: .main
                                ) { _ in w.alphaValue = 1 }
                            }
                        }
                    }
            }
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func tabButton(_ tab: TabsModel.Tab) -> some View {
        let active = tabs.activeId == tab.id
        let hasActivity = tabs.activityTabs.contains(tab.id)
        let neonActive = hasActivity && !active

        HStack(spacing: 4) {
            if renamingId == tab.id {
                TextField("", text: $renameText, onCommit: {
                    tabs.rename(tab.id, to: renameText)
                    renamingId = nil
                })
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(width: 110)
            } else {
                Text(tab.name)
                    .font(.system(size: 12, weight: neonActive ? .semibold : .regular))
                    .lineLimit(1)
            }
            if tabs.tabs.count > 1 {
                Button { tabs.close(tab.id) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .opacity(active ? 0.7 : 0.4)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .foregroundColor(neonActive ? Color.black.opacity(0.85) : nil)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    neonActive
                        ? appState.theme.neonAccentColor
                        : (active ? Color.white.opacity(0.10) : Color.clear)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            renameText = tab.name
            renamingId = tab.id
        }
        .onTapGesture {
            tabs.select(tab.id)
        }
    }
}

struct HeaderButtonStyle: ButtonStyle {
    var active: Bool = false
    var textColor: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundColor(textColor.opacity(active ? 1 : 0.75))
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                            ? Color.white.opacity(0.18)
                            : (active ? Color.white.opacity(0.10) : Color.clear)
                    )
            )
            .contentShape(Rectangle())
    }
}

// MARK: - Settings popover

struct SettingsView: View {
    @ObservedObject var glass: GlassSettings
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Glass Effect").font(.system(size: 13, weight: .medium))
                Spacer()
                Toggle("", isOn: $glass.enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if glass.enabled {
                VStack(alignment: .leading, spacing: 10) {
                    glassSlider("Opacity", value: $glass.transparency)
                    glassSlider("Blur", value: $glass.blurIntensity)
                    glassSlider("Tint", value: $glass.tintStrength)
                    glassSlider("Depth", value: $glass.backgroundVisibility)

                    HStack {
                        Text("Color").frame(width: 60, alignment: .leading)
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: glass.tintColorHex) },
                            set: { glass.tintColorHex = NSColor($0).hexString }
                        ))
                        .labelsHidden()
                        .frame(height: 22)
                    }
                }
                .font(.system(size: 12))
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Text").font(.system(size: 13, weight: .medium))
                HStack {
                    Text("Color").frame(width: 60, alignment: .leading)
                    if glass.useThemeText {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.foreground))
                            .frame(height: 22)
                    } else {
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: glass.textColorHex) },
                            set: { glass.textColorHex = NSColor($0).hexString }
                        ))
                        .labelsHidden()
                        .frame(height: 22)
                    }
                    Toggle("Theme", isOn: $glass.useThemeText)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                }
            }
            .font(.system(size: 12))

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Font").font(.system(size: 13, weight: .medium))
                HStack {
                    Text("Family").frame(width: 60, alignment: .leading)
                    Picker("", selection: $glass.fontName) {
                        ForEach(GlassSettings.availableFonts, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                HStack {
                    Text("Size").frame(width: 60, alignment: .leading)
                    Slider(value: $glass.fontSize, in: 9...28, step: 1)
                    Text("\(Int(glass.fontSize))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }
            }
            .font(.system(size: 12))
        }
        .padding(14)
    }

    @ViewBuilder
    private func glassSlider(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label).frame(width: 60, alignment: .leading)
            Slider(value: value, in: 0...1)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - Terminal area (NSViewRepresentable container)

/// Holds every tab's terminal as a subview and shows only the active one.
/// Keeping inactive terminals attached (just hidden) preserves their state.
final class TerminalContainerView: NSView {
    var leftInset: CGFloat = 32

    var activeTerminal: NSView? {
        didSet {
            for sub in subviews { sub.isHidden = (sub !== activeTerminal) }
            layoutTerminal(activeTerminal)
            if let t = activeTerminal { window?.makeFirstResponder(t) }
        }
    }

    func attach(_ term: NSView) {
        if !subviews.contains(term) {
            addSubview(term)
        }
        layoutTerminal(term)
    }

    func detach(_ term: NSView) {
        term.removeFromSuperview()
    }

    override func layout() {
        super.layout()
        for sub in subviews { layoutTerminal(sub) }
    }

    private func layoutTerminal(_ view: NSView?) {
        guard let view = view else { return }
        view.frame = NSRect(x: leftInset, y: 0,
                            width: max(0, bounds.width - leftInset),
                            height: bounds.height)
        view.autoresizingMask = [.width, .height]
    }
}

struct TerminalArea: NSViewRepresentable {
    @ObservedObject var tabs: TabsModel

    func makeNSView(context: Context) -> TerminalContainerView {
        TerminalContainerView()
    }

    func updateNSView(_ nsView: TerminalContainerView, context: Context) {
        // Attach any new terminals.
        let liveTerms = Set(tabs.tabs.map { ObjectIdentifier($0.terminal) })
        for tab in tabs.tabs {
            nsView.attach(tab.terminal)
        }
        // Remove any closed ones.
        for sub in nsView.subviews {
            if !liveTerms.contains(ObjectIdentifier(sub)) {
                sub.removeFromSuperview()
            }
        }
        // Show the active.
        if let active = tabs.tabs.first(where: { $0.id == tabs.activeId }) {
            if nsView.activeTerminal !== active.terminal {
                nsView.activeTerminal = active.terminal
            }
        }
    }
}
