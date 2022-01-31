//
//  AuthView.swift
//  Shared
//
//  Created by Alexander Schmutz on 15.08.21.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var msAuthState: MSAuthState

    private let msAuthAdapter: MSAuthAdapterProtocol = resolve()
    
    var body: some View {
        VStack(spacing: 40) {
            Text(msAuthState.account?.email ?? "Signed out")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.gray)

            Button("Login with interaction") {
                msAuthAdapter.login(withInteraction: true)
            }

            Button("Logout") {
                msAuthAdapter.logout()
            }
            .disabled(msAuthState.account == nil)

            Button("Load device mode") {
                msAuthAdapter.loadDeviceMode()
            }
            
            Text("See logged console output for more info")
                .font(.caption)

            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(MSAuthState())
    }
}
