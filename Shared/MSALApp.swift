//
//  MSALApp.swift
//  Shared
//
//  Created by Alexander Schmutz on 15.08.21.
//

import SwiftUI

@main
struct MSALApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    private let msAuthState: MSAuthState = resolve()
    private let msAuthAdapter: MSAuthAdapter = resolve()
    
    var body: some Scene {
        WindowGroup {
            AuthView()
                .onAppear {
                    msAuthAdapter.setupMSAuthentication()
                    msAuthAdapter.loadCurrentAccount()
                }
                .onChange(of: scenePhase) { scenePhase in
                    if scenePhase == .active {
                        msAuthAdapter.loadCurrentAccount()
                    }
                }
                .onOpenURL { url in
                    msAuthAdapter.openUrl(url: url)
                }
                .environmentObject(msAuthState)
        }
    }
}
