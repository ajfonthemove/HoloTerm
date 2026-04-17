import AppKit
import SwiftUI

// Adapted from LiquidGlassMail's GradientBackdrop.swift — the multi-layer
// glass compositor that makes blur tuneable and gives the effect its depth.

typealias Color = SwiftUI.Color

struct GlassAppearance {
    var transparency: Double = 0.72
    var blurIntensity: Double = 0.68
    var tintStrength: Double = 0.14
    var backgroundVisibility: Double = 0.96
    var tintColor: Color = Color(red: 0.53, green: 0.53, blue: 0.53)

    // Derived tint colours (secondary = lighter, depth = darker).
    var primaryTintColor: Color { tintColor }
    var secondaryTintColor: Color {
        tintColor.opacity(0.72).blendedWith(Color.white, fraction: 0.24)
    }
    var depthTintColor: Color {
        tintColor.opacity(0.56).blendedWith(Color.black, fraction: 0.56)
    }

    var backgroundBaseColor: Color { Color(red: 0.07, green: 0.07, blue: 0.07) }
    var luminousHighlightColor: Color { Color.white }

    // Remap transparency so slider 0% = 0.04, 100% = 1.0. This hides
    // the SwiftTerm cell-fill stipple at the low end while giving the
    // full range a finer progression.
    var effectiveTransparency: Double {
        0.04 + (transparency * 0.96)
    }

    // Blur-coupled values from the reference app's formulae.
    var backdropGaussianBlurRadius: CGFloat {
        CGFloat(6.0 + (blurIntensity * 30.0))
    }
    var backdropGaussianOpacity: Double {
        effectiveTransparency * (0.12 + (blurIntensity * 0.18))
    }
    var backdropMaterialOpacity: Double {
        effectiveTransparency * max(0.44, 0.42 + (blurIntensity * 0.22) - (backgroundVisibility * 0.08))
    }
    var backdropObfuscationOpacity: Double {
        effectiveTransparency * (0.14 + (blurIntensity * 0.42) + ((1.0 - backgroundVisibility) * 0.06))
    }
    var backdropNeutralScrimOpacity: Double {
        effectiveTransparency * (0.02 + (blurIntensity * 0.18))
    }
}

// MARK: - Main backdrop view

struct GradientBackdrop: View {
    let appearance: GlassAppearance

    var body: some View {
        let tintOpacity = appearance.tintStrength
        let glowStrength = appearance.backgroundVisibility * 0.18

        ZStack {
            // Layer 1: macOS material (behind-window blur, variable alpha).
            MaterialLayer(material: .underWindowBackground,
                          alpha: appearance.backdropMaterialOpacity)

            // Layer 2: Obfuscation (second material for density / privacy).
            MaterialLayer(material: .underWindowBackground,
                          alpha: appearance.backdropObfuscationOpacity)

            // Layer 3: Gaussian wash (SwiftUI .blur — THIS is the tuneable radius).
            GaussianWash(appearance: appearance)

            // Layer 4: Neutral scrim.
            Rectangle()
                .fill(appearance.backgroundBaseColor
                    .opacity(appearance.backdropNeutralScrimOpacity))

            // Layer 5: Tint colour wash (uniform — no diagonal fade).
            Rectangle()
                .fill(appearance.primaryTintColor.opacity(tintOpacity))

            // Layer 6: Atmospheric glows (four corners for even coverage).
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.primaryTintColor.opacity(0.26 * glowStrength),
                            appearance.secondaryTintColor.opacity(0.06 * glowStrength),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 280
                    )
                )
                .frame(width: 520, height: 520)
                .offset(x: -280, y: -250)
                .blur(radius: 18)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.secondaryTintColor.opacity(0.18 * glowStrength),
                            appearance.primaryTintColor.opacity(0.04 * glowStrength),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 360
                    )
                )
                .frame(width: 680, height: 620)
                .offset(x: 340, y: -110)
                .blur(radius: 34)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.luminousHighlightColor
                                .opacity(0.08 * appearance.backgroundVisibility),
                            appearance.luminousHighlightColor
                                .opacity(0.02 * appearance.backgroundVisibility),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 340
                    )
                )
                .frame(width: 620, height: 480)
                .offset(x: -220, y: 260)
                .blur(radius: 58)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.primaryTintColor.opacity(0.20 * glowStrength),
                            appearance.secondaryTintColor.opacity(0.05 * glowStrength),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 320
                    )
                )
                .frame(width: 600, height: 540)
                .offset(x: 260, y: 220)
                .blur(radius: 40)

            // Layer 7: Top luminous gradient (subtle top-light feel).
            LinearGradient(
                colors: [
                    appearance.luminousHighlightColor.opacity(0.008),
                    appearance.backgroundBaseColor.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - NSVisualEffectView wrapper (used twice — once for material, once for obfuscation)

private struct MaterialLayer: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let alpha: Double

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.state = .active
        v.blendingMode = .behindWindow
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.state = .active
        v.blendingMode = .behindWindow
        v.material = material
        v.alphaValue = CGFloat(alpha)
    }
}

// MARK: - Gaussian wash layer (SwiftUI shapes + .blur for tuneable radius)

private struct GaussianWash: View {
    let appearance: GlassAppearance

    var body: some View {
        ZStack {
            Rectangle()
                .fill(appearance.backgroundBaseColor.opacity(0.14))

            Rectangle()
                .fill(appearance.primaryTintColor
                    .opacity(appearance.tintStrength * 0.5))

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.luminousHighlightColor
                                .opacity(0.12 * appearance.backgroundVisibility),
                            appearance.primaryTintColor
                                .opacity(0.08 * appearance.backgroundVisibility),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 420
                    )
                )
                .frame(width: 760, height: 560)
                .offset(x: -240, y: -180)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.secondaryTintColor
                                .opacity(0.10 * appearance.backgroundVisibility),
                            appearance.backgroundBaseColor.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 420
                    )
                )
                .frame(width: 820, height: 620)
                .offset(x: 260, y: 200)
        }
        .compositingGroup()
        .blur(radius: appearance.backdropGaussianBlurRadius)
        .opacity(appearance.backdropGaussianOpacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Colour blending helper

extension Color {
    func blendedWith(_ other: Color, fraction: Double) -> Color {
        // We can't decompose SwiftUI.Color easily, so use a visual approximation
        // by stacking opacities. For the glass effect this is good enough.
        self.opacity(1 - fraction)
    }
}
