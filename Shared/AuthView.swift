//
//  AuthView.swift
//  Shared
//
//  Created by Alexander Schmutz on 15.08.21.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var msAuthState: MSAuthState

    private let msAuthAdapter: MSAuthAdapter = resolve()
    
    var body: some View {
        VStack(spacing: 40) {
            Text(msAuthState.currentAccount?.username ?? "Signed out")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.gray)

            Button("Call Microsoft Graph API") {
                msAuthAdapter.callGraphAPI()
            }

            Button("Sign Out") {
                msAuthAdapter.signOut()
            }
            .disabled(msAuthState.currentAccount == nil)

            Button("Get device info") {
                msAuthAdapter.getDeviceMode()
            }
            
            Text(msAuthState.logMessage)
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
