//
//  JackpotDisplay.swift
//  PacaStop
//
//  The slot-machine display, repurposed to count money KEPT. Marquee bulbs, the AI STRÂNS
//  label, the amount as glowing lime digit "reels" (with live-ticking last digits), and a
//  caption. Scales the reel row down gracefully as the number grows.
//

import SwiftUI

struct JackpotDisplay: View {
    let amount: Double
    let topLabel: String
    let bottomLabel: String
    var decimals: Int = 2

    var body: some View {
        VStack(spacing: Spacing.md) {
            MarqueeBulbs()
            Text(topLabel.uppercased())
                .font(Typo.kicker)
                .tracking(3.5)
                .foregroundStyle(Palette.lime.opacity(0.9))
            ReelRow(text: MoneyFormatter.number(amount, decimals: decimals))
            Text(bottomLabel)
                .font(Typo.caption)
                .foregroundStyle(Palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .background(
            RadialGradient(
                colors: [Color(hex: 0x20241A), Color(hex: 0x0E0F13)],
                center: .top, startRadius: 0, endRadius: 260
            ),
            in: RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous)
                .strokeBorder(Palette.lime.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(topLabel) \(MoneyFormatter.lei(amount, decimals: decimals))")
    }
}

/// The row of reel cells + separators + the "lei" suffix, scaled to fit its width.
private struct ReelRow: View {
    let text: String

    private var digitCount: Int { text.filter(\.isNumber).count }

    // Cell size shrinks as the number gets longer, so it always fits.
    private var cellWidth: CGFloat {
        switch digitCount {
        case 0...4: 34
        case 5: 30
        case 6: 26
        default: 22
        }
    }
    private var cellHeight: CGFloat { cellWidth * 1.58 }
    private var glyphSize: CGFloat { cellWidth * 1.05 }

    /// A cell keyed by place value (distance from the right) so identity is stable as the
    /// number grows — digits keep rolling cleanly across width/separator changes.
    private struct Cell: Identifiable {
        let id: String
        let isDigit: Bool
        let char: String
    }

    private var cells: [Cell] {
        let chars = Array(text)
        let n = chars.count
        return chars.enumerated().map { i, ch in
            let fromRight = n - 1 - i
            let isDigit = ch.isNumber
            return Cell(id: "\(isDigit ? "d" : "s")-\(fromRight)", isDigit: isDigit, char: String(ch))
        }
    }

    var body: some View {
        let naturalWidth = estimatedWidth()
        GeometryReader { geo in
            let scale = min(1, geo.size.width / max(1, naturalWidth))
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(cells) { cell in
                    if cell.isDigit {
                        ReelCell(digit: cell.char, width: cellWidth, height: cellHeight, glyphSize: glyphSize)
                    } else {
                        Text(cell.char)
                            .font(.display(glyphSize * 0.8))
                            .foregroundStyle(Palette.lime.opacity(0.75))
                            .padding(.bottom, cellHeight * 0.1)
                    }
                }
                Text("lei")
                    .font(.display(glyphSize * 0.55))
                    .foregroundStyle(Palette.lime.opacity(0.7))
                    .padding(.bottom, cellHeight * 0.14)
                    .padding(.leading, 4)
            }
            .scaleEffect(scale, anchor: .center)
            .frame(width: geo.size.width, height: cellHeight, alignment: .center)
        }
        .frame(height: cellHeight)
    }

    private func estimatedWidth() -> CGFloat {
        var w: CGFloat = 0
        for ch in text {
            w += ch.isNumber ? cellWidth : glyphSize * 0.5
            w += 4
        }
        w += glyphSize * 0.55 * 2 + 8   // "lei"
        return w
    }
}

/// A single glowing digit reel cell.
private struct ReelCell: View {
    let digit: String
    let width: CGFloat
    let height: CGFloat
    let glyphSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.reel, style: .continuous)
                .fill(Palette.desk)
                .overlay(
                    LinearGradient(
                        colors: [.white.opacity(0.06), .clear, .black.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.reel, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.reel, style: .continuous)
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                )

            Text(digit)
                .font(.display(glyphSize))
                .foregroundStyle(Palette.lime)
                .shadow(color: Palette.lime.opacity(0.6), radius: 10)
                .contentTransition(.numericText(countsDown: false))

            Rectangle()
                .fill(.black.opacity(0.6))
                .frame(height: 1)
        }
        .frame(width: width, height: height)
        .animation(Motion.counterTick, value: digit)
    }
}

#Preview {
    ZStack {
        Palette.background.ignoresSafeArea()
        VStack(spacing: 20) {
            JackpotDisplay(amount: 1131.42, topLabel: "AI STRÂNS", bottomLabel: "de când nu mai hrănești aparatul")
            JackpotDisplay(amount: 128456.90, topLabel: "AI STRÂNS", bottomLabel: "de când nu mai hrănești aparatul")
        }
        .padding()
    }
}
