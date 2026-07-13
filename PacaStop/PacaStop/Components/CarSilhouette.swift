//
//  CarSilhouette.swift
//  PacaStop
//
//  The status metaphor (§3.5). A clean, minimalist side-profile that visibly improves
//  tier by tier: dull/boxy/broken junker (grey, exhaust smoke, red warning light) →
//  sleek/low/premium with lime accents. Drawn from simple shapes in a canonical 200×112
//  space and scaled to the requested width.
//

import SwiftUI

struct CarSilhouette: View {
    let tier: CarTier
    var width: CGFloat = 200
    var floating: Bool = false

    @State private var floatOffset: CGFloat = 0

    private let canonicalWidth: CGFloat = 200
    private let canonicalHeight: CGFloat = 112

    private var scale: CGFloat { width / canonicalWidth }
    private var style: CarStyle { CarStyle.forTier(tier) }

    var body: some View {
        canvas
            .frame(width: canonicalWidth, height: canonicalHeight)
            .scaleEffect(scale)
            .frame(width: width, height: canonicalHeight * scale)
            .offset(y: floatOffset)
            .onAppear {
                guard floating else { return }
                withAnimation(Motion.float) { floatOffset = -6 }
            }
            .accessibilityHidden(true)
    }

    private var canvas: some View {
        ZStack {
            // Ground shadow
            Ellipse()
                .fill(.black.opacity(0.45))
                .frame(width: 150, height: 10)
                .blur(radius: 6)
                .offset(y: 50)

            // Exhaust smoke (junker only)
            if style.showSmoke {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(white: 0.5).opacity(0.28 - Double(i) * 0.07))
                        .frame(width: CGFloat(12 + i * 6))
                        .offset(x: -95 - CGFloat(i * 12), y: 24 - CGFloat(i * 6))
                        .blur(radius: 2)
                }
            }

            // Main body
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(style.body)
                .frame(width: 176, height: 34)
                .offset(y: 20)

            // Cabin / roof
            CabinShape(sleekness: style.sleekness)
                .fill(style.roof)
                .frame(width: 92, height: 30)
                .offset(x: -2, y: -2)

            // Window
            CabinShape(sleekness: style.sleekness)
                .fill(style.window)
                .frame(width: 74, height: 20)
                .offset(x: -2, y: 1)

            // Accent stripe (premium tiers)
            if let accent = style.accentStripe {
                Capsule()
                    .fill(accent)
                    .frame(width: 150, height: 3)
                    .offset(y: 30)
            }

            // Headlight (front, right)
            RoundedRectangle(cornerRadius: 2)
                .fill(style.headlight)
                .frame(width: 6, height: 8)
                .shadow(color: style.headlight.opacity(0.9), radius: 5)
                .offset(x: 84, y: 16)

            // Rear light / warning
            RoundedRectangle(cornerRadius: 2)
                .fill(style.rearLight)
                .frame(width: 4, height: style.showWarning ? 9 : 7)
                .shadow(color: style.rearLight.opacity(0.8), radius: style.showWarning ? 6 : 3)
                .offset(x: -85, y: 16)

            // Wheels
            wheel.offset(x: -52, y: 40)
            wheel.offset(x: 52, y: 40)
        }
    }

    private var wheel: some View {
        ZStack {
            Circle().fill(Color(hex: 0x1C1E22)).frame(width: 30, height: 30)
            Circle().strokeBorder(style.rim, lineWidth: 5).frame(width: 30, height: 30)
            Circle().fill(style.rim.opacity(0.9)).frame(width: 7, height: 7)
        }
    }
}

/// A rounded cabin/greenhouse shape (rounded top, squarer bottom).
private struct CabinShape: Shape {
    var sleekness: CGFloat   // 0 = boxy, 1 = sleek/low

    func path(in rect: CGRect) -> Path {
        let r = rect.height * (0.5 + sleekness * 0.4)
        let frontSlant = rect.width * (0.12 + sleekness * 0.16)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r * 0.5))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + r * 0.7, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX - frontSlant, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + r),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Per-tier visual parameters.
private struct CarStyle {
    var body: Color
    var roof: Color
    var window: Color
    var rim: Color
    var headlight: Color
    var rearLight: Color
    var accentStripe: Color?
    var sleekness: CGFloat
    var showSmoke: Bool
    var showWarning: Bool

    static func forTier(_ tier: CarTier) -> CarStyle {
        switch tier {
        case .rabla:
            CarStyle(body: Color(hex: 0x9BA0A6), roof: Color(hex: 0x8A9096), window: Color(hex: 0x2F353C),
                     rim: Color(hex: 0xD9DEE3), headlight: Color(hex: 0xF4F6DF), rearLight: Palette.red,
                     accentStripe: nil, sleekness: 0.0, showSmoke: true, showWarning: true)
        case .trezit:
            CarStyle(body: Color(hex: 0x7E8A96), roof: Color(hex: 0x6E7A86), window: Color(hex: 0x2A3038),
                     rim: Color(hex: 0xC7CDD4), headlight: Color(hex: 0xF4F6DF), rearLight: Color(hex: 0xC24A44),
                     accentStripe: nil, sleekness: 0.25, showSmoke: false, showWarning: false)
        case .viteza:
            CarStyle(body: Color(hex: 0xC3C9D0), roof: Color(hex: 0xB3BAC2), window: Color(hex: 0x2F353C),
                     rim: Color(hex: 0xE1E6EB), headlight: Color(hex: 0xFFF7D6), rearLight: Color(hex: 0xD24A44),
                     accentStripe: nil, sleekness: 0.45, showSmoke: false, showWarning: false)
        case .serios:
            CarStyle(body: Color(hex: 0x39435A), roof: Color(hex: 0x2E374B), window: Color(hex: 0x1B2130),
                     rim: Color(hex: 0xAEB6C2), headlight: Color(hex: 0xEAF2FF), rearLight: Color(hex: 0xE0362B),
                     accentStripe: Color(hex: 0x4E7BE0), sleekness: 0.6, showSmoke: false, showWarning: false)
        case .smecher:
            CarStyle(body: Color(hex: 0xD5DAE0), roof: Color(hex: 0xC2C8D0), window: Color(hex: 0x20252D),
                     rim: Color(hex: 0xEFF3F7), headlight: Color(hex: 0xFFFFFF), rearLight: Color(hex: 0xE0362B),
                     accentStripe: Color(hex: 0xB9C0C8), sleekness: 0.78, showSmoke: false, showWarning: false)
        case .legenda:
            CarStyle(body: Color(hex: 0x171A1F), roof: Color(hex: 0x0F1114), window: Color(hex: 0x0A0B0D),
                     rim: Palette.lime, headlight: Palette.lime, rearLight: Palette.red,
                     accentStripe: Palette.lime, sleekness: 1.0, showSmoke: false, showWarning: false)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(CarTier.allCases) { tier in
                CarSilhouette(tier: tier, width: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    .background(Palette.background)
}
