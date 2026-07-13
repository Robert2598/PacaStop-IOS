//
//  PacaTabBar.swift
//  PacaStop
//
//  The persistent bottom tab bar (Acasă · Progres · Setări). Active tab = lime.
//  Custom-drawn to match the design (native TabView chrome doesn't fit the aesthetic).
//

import SwiftUI

enum MainTab: Int, CaseIterable, Hashable {
    case home, progress, mentor, settings

    var iconActive: String {
        switch self {
        case .home: "house.fill"
        case .progress: "chart.bar.fill"
        case .mentor: "bubble.left.and.bubble.right.fill"
        case .settings: "slider.horizontal.3"
        }
    }
    var iconInactive: String {
        switch self {
        case .home: "house"
        case .progress: "chart.bar"
        case .mentor: "bubble.left.and.bubble.right"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct PacaTabBar: View {
    @Binding var selection: MainTab
    let label: (MainTab) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                let isActive = tab == selection
                Button {
                    guard selection != tab else { return }
                    withAnimation(Motion.snappy) { selection = tab }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: isActive ? tab.iconActive : tab.iconInactive)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(height: 22)
                        Text(label(tab))
                            .font(.body(10.5, weight: .semibold))
                    }
                    .foregroundStyle(isActive ? Palette.lime : Palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(tab))
                .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, Spacing.xs)
        .background(
            Color(hex: 0x0F1014).opacity(0.98)
                .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    struct Wrapper: View {
        @State var sel: MainTab = .home
        var body: some View {
            VStack {
                Spacer()
                PacaTabBar(selection: $sel) { tab in
                    switch tab {
                    case .home: "Acasă"; case .progress: "Progres"; case .mentor: "Mentor"; case .settings: "Setări"
                    }
                }
            }
            .background(Palette.background)
        }
    }
    return Wrapper()
}
