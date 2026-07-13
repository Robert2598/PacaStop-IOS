//
//  PacaButton.swift
//  PacaStop
//
//  The app's button set. Lime = primary CTA, dark = secondary (Google), red-outline =
//  the ONJN step, ghost = tertiary. (Sign in with Apple uses the native system button.)
//

import SwiftUI

enum PacaButtonKind {
    case lime, white, dark, redOutline, ghost

    var background: Color {
        switch self {
        case .lime: Palette.lime
        case .white: Palette.textPrimary
        case .dark: Palette.surface
        case .redOutline, .ghost: .clear
        }
    }
    var foreground: Color {
        switch self {
        case .lime: Palette.onLime
        case .white: Palette.background
        case .dark: Palette.textPrimary
        case .redOutline: Palette.red
        case .ghost: Palette.textSecondary
        }
    }
    var border: Color? {
        switch self {
        case .dark: Palette.hairlineStrong
        case .redOutline: Palette.red.opacity(0.6)
        default: nil
        }
    }
}

struct PacaButton: View {
    let title: String
    var kind: PacaButtonKind = .lime
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView().tint(kind.foreground)
                } else {
                    if let icon {
                        Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                    }
                    Text(title).font(Typo.button)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.primaryButtonHeight)
            .foregroundStyle(kind.foreground)
            .background(kind.background, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .strokeBorder(kind.border ?? .clear, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(PressableScale())
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    ZStack {
        Palette.background.ignoresSafeArea()
        VStack(spacing: 14) {
            PacaButton(title: "ÎNCEP ACUM", kind: .lime) {}
            PacaButton(title: "Continuă cu Google", kind: .dark, icon: "g.circle.fill") {}
            PacaButton(title: "Înscrie-mă în autoexcludere", kind: .redOutline) {}
            PacaButton(title: "Restaurează achiziția", kind: .ghost) {}
            PacaButton(title: "Se încarcă…", kind: .lime, isLoading: true) {}
            PacaButton(title: "Dezactivat", kind: .lime, isEnabled: false) {}
        }
        .padding()
    }
}
