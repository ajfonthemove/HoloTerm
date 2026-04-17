import AppKit
import SwiftUI
import Combine
import SwiftTerm

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    let appState     = AppState()
    let glass        = GlassSettings()
    let tabs         = TabsModel()

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rect = NSRect(x: 0, y: 0, width: 960, height: 640)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "HoloTerm"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 480, height: 320)
        window.center()
        // Required for vibrancy to actually capture the desktop behind.
        window.isOpaque = false
        window.backgroundColor = .clear

        // The entire UI is SwiftUI. GradientBackdrop (inside ContentView)
        // brings its own NSVisualEffectView via NSViewRepresentable, so we
        // don't need a separate AppKit vibrancy layer.
        let root = ContentView(
            appState: appState,
            glass: glass,
            tabs: tabs,
            onNewTab: { [weak self] in self?.newTab() }
        )
        let host = NSHostingView(rootView: root)
        host.frame = rect
        host.autoresizingMask = [.width, .height]

        window.contentView = host
        window.makeKeyAndOrderFront(nil)

        // Open the first tab.
        newTab()

        // React to settings changes — re-apply text colour / font + trigger redraw.
        glass.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyTheme() }
            .store(in: &cancellables)

        // Keyboard shortcuts (cmd-T / cmd-W / cmd-1..9 / cmd-shift-[/]).
        installKeyMonitor()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Tabs

    private func newTab() {
        let term = makeTerminal()
        applyTheme(to: term)
        let tab = TabsModel.Tab(id: UUID(), name: "Session \(tabs.tabs.count + 1)", terminal: term)
        tabs.add(tab)
        startProcess(in: term)
    }

    private func makeTerminal() -> LocalProcessTerminalView {
        let term = LocalProcessTerminalView(frame: .zero)
        term.processDelegate = self
        // Critical: keep cell-back AND CALayer transparent so the
        // GradientBackdrop layers show through.
        term.nativeBackgroundColor = .clear
        term.wantsLayer = true
        term.layer?.backgroundColor = NSColor.clear.cgColor
        // Hide SwiftTerm's legacy scrollbar.
        for sub in term.subviews where sub is NSScroller {
            sub.isHidden = true
        }
        return term
    }

    private func startProcess(in term: LocalProcessTerminalView) {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env: [String] = ["TERM=xterm-256color"]
        for k in ["HOME", "USER", "LANG", "LC_ALL", "PATH", "SHELL"] {
            if let v = ProcessInfo.processInfo.environment[k] {
                env.append("\(k)=\(v)")
            }
        }
        term.startProcess(executable: shell, args: ["-l"], environment: env)
    }

    // MARK: - Apply settings

    private func applyTheme() {
        for tab in tabs.tabs {
            applyTheme(to: tab.terminal)
        }
    }

    private func applyTheme(to term: LocalProcessTerminalView) {
        let theme = appState.theme
        term.installColors(theme.ansiPalette)
        term.nativeForegroundColor = glass.effectiveTextColor(for: theme)
        // Font — SwiftTerm recalculates cell dimensions automatically.
        if let font = NSFont(name: glass.fontName, size: CGFloat(glass.fontSize)) {
            if term.font.fontName != font.fontName || term.font.pointSize != font.pointSize {
                term.font = font
            }
        }
        term.needsDisplay = true
    }

    // MARK: - Keyboard shortcuts

    private func installKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let cmd = event.modifierFlags.contains(.command)
            let shift = event.modifierFlags.contains(.shift)
            let chars = event.charactersIgnoringModifiers ?? ""

            if cmd && !shift && chars == "t" {
                self.newTab(); return nil
            }
            if cmd && !shift && chars == "w" {
                if let id = self.tabs.activeId, self.tabs.tabs.count > 1 {
                    self.tabs.close(id)
                }
                return nil
            }
            if cmd && !shift, let n = Int(chars), (1...9).contains(n) {
                self.tabs.selectIndex(n - 1); return nil
            }
            if cmd && shift && chars == "}" {
                self.tabs.cycle(1); return nil
            }
            if cmd && shift && chars == "{" {
                self.tabs.cycle(-1); return nil
            }
            return event
        }
    }
}

// MARK: - Terminal process delegate

extension AppDelegate: LocalProcessTerminalViewDelegate {
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        if let tab = tabs.tabs.first(where: { $0.terminal === source }), !title.isEmpty {
            tabs.rename(tab.id, to: title)
        }
        if source === activeTerminal() {
            window.title = title.isEmpty ? "HoloTerm" : title
        }
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        if let term = source as? LocalProcessTerminalView {
            startProcess(in: term)
        }
    }

    private func activeTerminal() -> LocalProcessTerminalView? {
        tabs.tabs.first(where: { $0.id == tabs.activeId })?.terminal
    }
}
