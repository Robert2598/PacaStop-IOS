//
//  ProgressBars.swift
//  PacaStop
//
//  Two bars: the onboarding 4-segment step indicator and the car-tier progress bar.
//

import SwiftUI

/// The onboarding "PASUL n DIN 4" segmented indicator.
struct SegmentedProgressBar: View {
    let total: Int
    let current: Int          // 1-based
    var accessibilityLabelText: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < current ? Palette.lime : Palette.hairlineStrong)
                    .frame(height: 4)
                    .animation(Motion.snappy, value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText ?? "Step \(current) of \(total)")
    }
}

/// The lime car-progress bar (fills toward the next tier).
struct LinearProgressBar: View {
    let progress: Double      // 0…1
    var height: CGFloat = 8
    var tint: Color = Palette.lime

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.hairlineStrong)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .shadow(color: tint.opacity(0.5), radius: 6, y: 0)
            }
        }
        .frame(height: height)
        .animation(Motion.smooth, value: progress)
    }
}

#Preview {
    ZStack {
        Palette.background.ignoresSafeArea()
        VStack(spacing: 30) {
            SegmentedProgressBar(total: 4, current: 3).padding(.horizontal, 40)
            LinearProgressBar(progress: 0.42).padding(.horizontal, 40)
        }
    }
}
