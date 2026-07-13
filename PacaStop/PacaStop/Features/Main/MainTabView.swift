//
//  MainTabView.swift
//  PacaStop
//
//  The main app shell: the three tabs (Acasă · Progres · Setări) with the persistent
//  custom tab bar. Panic and Garage are presented from within Home.
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc

    var body: some View {
        @Bindable var router = env.router

        VStack(spacing: 0) {
            ZStack {
                switch router.mainTab {
                case .home: HomeView()
                case .progress: ProgressScreen()
                case .mentor: ChatView()
                case .settings: SettingsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)

            PacaTabBar(selection: $router.mainTab, label: tabLabel)
        }
        .background(Palette.background.ignoresSafeArea())
    }

    private func tabLabel(_ tab: MainTab) -> String {
        switch tab {
        case .home: loc.s.tabHome
        case .progress: loc.s.tabProgress
        case .mentor: loc.s.tabMentor
        case .settings: loc.s.tabSettings
        }
    }
}

#Preview {
    PreviewEnvironment { MainTabView() }
}
