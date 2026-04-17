import AppKit
import SwiftUI
import SwiftTerm
// `Color` typealias for SwiftUI.Color is declared in GradientBackdrop.swift.

// MARK: - Hex helpers

func parseHex(_ hex: String) -> (r: Double, g: Double, b: Double) {
    let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    var rgb: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&rgb)
    return (
        Double((rgb >> 16) & 0xff) / 255,
        Double((rgb >> 8) & 0xff) / 255,
        Double(rgb & 0xff) / 255
    )
}

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let (r, g, b) = parseHex(hex)
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }

    var hexString: String {
        let c = usingColorSpace(.sRGB) ?? .black
        let r = Int((c.redComponent * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}

extension Color {
    init(hex: String) {
        let (r, g, b) = parseHex(hex)
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

func swiftTermColor(_ hex: String) -> SwiftTerm.Color {
    let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    var rgb: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&rgb)
    let r = UInt8((rgb >> 16) & 0xff)
    let g = UInt8((rgb >> 8) & 0xff)
    let b = UInt8(rgb & 0xff)
    return SwiftTerm.Color(
        red: (UInt16(r) << 8) | UInt16(r),
        green: (UInt16(g) << 8) | UInt16(g),
        blue: (UInt16(b) << 8) | UInt16(b)
    )
}

// MARK: - Theme model (slim — just ANSI palette + accent + foreground)

struct Theme: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let accent: String         // hex — used for tab activity dot
    let foreground: String     // hex — default terminal text colour
    let ansi: [String]         // 16 hex strings: black…white, brightBlack…brightWhite

    var ansiPalette: [SwiftTerm.Color] {
        ansi.map { swiftTermColor($0) }
    }

    static let bundled: [Theme] = [
        Theme(id: "dracula", name: "Dracula", accent: "#bd93f9", foreground: "#f8f8f2",
              ansi: ["#21222c","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#f8f8f2",
                     "#6272a4","#ff6e6e","#69ff94","#ffffa5","#d6acff","#ff92df","#a4ffff","#ffffff"]),

        Theme(id: "nord", name: "Nord", accent: "#88c0d0", foreground: "#d8dee9",
              ansi: ["#3b4252","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#88c0d0","#e5e9f0",
                     "#4c566a","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#8fbcbb","#eceff4"]),

        Theme(id: "tokyo-night", name: "Tokyo Night", accent: "#7aa2f7", foreground: "#a9b1d6",
              ansi: ["#414868","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#c0caf5",
                     "#414868","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#c0caf5"]),

        Theme(id: "catppuccin", name: "Catppuccin Mocha", accent: "#cba6f7", foreground: "#cdd6f4",
              ansi: ["#45475a","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#bac2de",
                     "#585b70","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#a6adc8"]),

        Theme(id: "rose-pine", name: "Rose Pine", accent: "#c4a7e7", foreground: "#e0def4",
              ansi: ["#26233a","#eb6f92","#31748f","#f6c177","#9ccfd8","#c4a7e7","#ebbcba","#e0def4",
                     "#6e6a86","#eb6f92","#31748f","#f6c177","#9ccfd8","#c4a7e7","#ebbcba","#e0def4"]),

        Theme(id: "gruvbox", name: "Gruvbox Dark", accent: "#fabd2f", foreground: "#ebdbb2",
              ansi: ["#282828","#cc241d","#98971a","#d79921","#458588","#b16286","#689d6a","#a89984",
                     "#928374","#fb4934","#b8bb26","#fabd2f","#83a598","#d3869b","#8ec07c","#ebdbb2"]),

        Theme(id: "one-dark", name: "One Dark", accent: "#61afef", foreground: "#abb2bf",
              ansi: ["#282c34","#e06c75","#98c379","#e5c07b","#61afef","#c678dd","#56b6c2","#abb2bf",
                     "#5c6370","#e06c75","#98c379","#e5c07b","#61afef","#c678dd","#56b6c2","#ffffff"]),

        Theme(id: "solarized", name: "Solarized Dark", accent: "#268bd2", foreground: "#839496",
              ansi: ["#073642","#dc322f","#859900","#b58900","#268bd2","#d33682","#2aa198","#eee8d5",
                     "#002b36","#cb4b16","#586e75","#657b83","#839496","#6c71c4","#93a1a1","#fdf6e3"]),

        Theme(id: "kanagawa", name: "Kanagawa", accent: "#7e9cd8", foreground: "#dcd7ba",
              ansi: ["#090618","#c34043","#76946a","#c0a36e","#7e9cd8","#957fb8","#6a9589","#c8c093",
                     "#727169","#e82424","#98bb6c","#e6c384","#7fb4ca","#938aa9","#7aa89f","#dcd7ba"]),

        Theme(id: "github-dark", name: "GitHub Dark", accent: "#58a6ff", foreground: "#c9d1d9",
              ansi: ["#484f58","#ff7b72","#3fb950","#d29922","#58a6ff","#bc8cff","#39c5cf","#b1bac4",
                     "#6e7681","#ffa198","#56d364","#e3b341","#79c0ff","#d2a8ff","#56d4dd","#f0f6fc"]),

        Theme(id: "synthwave", name: "Synthwave '84", accent: "#ff7edb", foreground: "#f0e6ff",
              ansi: ["#1e1a2e","#fe4450","#72f1b8","#fede5d","#36f9f6","#ff7edb","#36f9f6","#f0e6ff",
                     "#625d7a","#fe4450","#72f1b8","#f3e70f","#03edf9","#ff7edb","#03edf9","#ffffff"]),

        Theme(id: "monokai", name: "Monokai Pro", accent: "#ffd866", foreground: "#fcfcfa",
              ansi: ["#403e41","#ff6188","#a9dc76","#ffd866","#fc9867","#ab9df2","#78dce8","#fcfcfa",
                     "#727072","#ff6188","#a9dc76","#ffd866","#fc9867","#ab9df2","#78dce8","#fcfcfa"]),
    ]

    static let `default`: Theme = bundled[0]

    static func find(id: String) -> Theme {
        bundled.first { $0.id == id } ?? .default
    }
}
