//
//  MarqueeBulbs.swift
//  PacaStop
//
//  A row of marquee bulbs that blink in a staggered chase — the ironic casino frame
//  around the "money kept" jackpot.
//

import SwiftUI

struct MarqueeBulbs: View {
    var count: Int = 7
    var step: TimeInterval = 0.15

    var body: some View {
        TimelineView(.periodic(from: .now, by: step)) { context in
            let head = Int(context.date.timeIntervalSinceReferenceDate / step) % count
            HStack(spacing: 9) {
                ForEach(0..<count, id: \.self) { i in
                    let lit = i == head || i == (head + 1) % count
                    Circle()
                        .fill(Palette.lime)
                        .frame(width: 8, height: 8)
                        .opacity(lit ? 1 : 0.28)
                        .shadow(color: Palette.lime.opacity(lit ? 0.9 : 0), radius: lit ? 6 : 0)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack { Palette.background.ignoresSafeArea(); MarqueeBulbs() }
}
