# HoloTerm

<img width="733" height="330" alt="ChatGPT Image Apr 17, 2026, 01_17_24 AM" src="https://github.com/user-attachments/assets/ec283366-8900-4b7e-9860-96a2e2c44d0c" />

**Your desktop, your terminal, one window.**

Most terminal apps make you choose: either you stare at an opaque black rectangle that hides everything behind it, or you tile a dozen windows across your screen trying to keep context. HoloTerm doesn't ask you to choose.

HoloTerm is a native macOS terminal that sits *on* your desktop instead of *over* it. The glass effect isn't a gimmick — it's the point. You keep your reference material, your browser, your notes visible right through the terminal while you work. No alt-tabbing. No split-screen juggling. No losing your place.

One window. Full terminal. Full view.

## Why glass matters

Every time you switch windows, you lose a thought. Every time you tile your screen into four cramped quadrants, you lose space. HoloTerm gives you a terminal with real tabs, real keyboard shortcuts, and a real shell — but the window is transparent enough that the rest of your screen stays useful.

Need to reference a design while running a build? Leave HoloTerm over the mockup. Watching logs while reading docs? You can see both. The terminal becomes a layer in your workflow instead of a wall in front of it.

## What you get

- **Tabs** — Cmd-T, Cmd-W, Cmd-1 through 9. Double-click to rename. Activity indicators when a background tab has new output.
- **Glass that actually works** — not a CSS approximation. Native macOS vibrancy with a multi-layer compositor. Four sliders: opacity, blur, tint strength, and depth. One color picker. That's it.
- **Pick your text color and font** — any font on your system, any color you want. No theme lock-in.
- **3.9 MB** — not 200 MB. No Chromium. No Electron. No Node. Pure Swift.
- **Login shell by default** — Homebrew, nvm, claude, whatever you've got in your `.zprofile` just works.

## Install

```sh
git clone https://github.com/ajfonthemove/HoloTerm.git
cd HoloTerm
swift build -c release
```

The built binary is at `.build/release/Terminal`. To bundle it as a proper `.app`:

```sh
mkdir -p build/HoloTerm.app/Contents/{MacOS,Resources}
cp .build/release/Terminal build/HoloTerm.app/Contents/MacOS/HoloTerm
```

Add an `Info.plist` and an `.icns` icon to `Contents/` and `Contents/Resources/` respectively, then drop `HoloTerm.app` into `/Applications`.

## Requirements

- macOS 13+
- Swift 5.9+

## License

MIT
