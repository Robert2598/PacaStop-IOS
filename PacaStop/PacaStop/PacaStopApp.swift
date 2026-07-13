//
//  PacaStopApp.swift
//  PacaStop
//
//  App entry point. Builds the DI container, injects the stores/services into the
//  environment, and drives lifecycle hooks.
//

import SwiftUI
import SwiftData

@main
struct PacaStopApp: App {
    @State private var env = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .environment(env.loc)
                .environment(env.prefs)
                .environment(env.router)
                .environment(env.appModel)
                .modelContainer(env.modelContainer)
                .task { env.start() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { env.onBecameActive() }
                }
        }
    }
}
