//
//  MSAuthAdapter.swift
//  ace-life
//
//  Created by Alexander Schmutz on 07.08.21.
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//

import UIKit
import OSLog

protocol MSAuthAdapterProtocol {
    func setupViewConnection()
    func login(withInteraction: Bool)
    func logout()
    func openUrl(url: URL)
    func loadDeviceMode()
}

class MSAuthAdapter: MSAuthAdapterProtocol {

    private let msGraphEndpoint = "https://graph.microsoft.com"
    private let msAuthority: String = "https://login.microsoftonline.com/\(MSAuthCredentials.directoryId)"
    private let msRedirectUri = "msauth.\(Bundle.main.bundleIdentifier!)://auth"
    private let msScopes: [String] = ["User.Read"]
    
    private let appState: MSAuthState
    private let msAuthProxy: MSAuthProxyProtocol
    
    private var accessToken: String? // TODO: Use keychain to store accessToken
    
    init(
        appState: MSAuthState = resolve(),
        msAuthProxy: MSAuthProxyProtocol = resolve()
    ) {
        self.appState = appState
        self.msAuthProxy = msAuthProxy
        setupApplicationContext()
    }

    /// needs to be called after the view was initialised so the topViewController can be found
    func setupViewConnection() {
        if let topViewController = UIApplication.topViewController {
            msAuthProxy.connectWith(viewController: topViewController)
        }
    }

    func login(withInteraction: Bool) {
        loadAccount { account in
            if account != nil {
                self.acquireTokenSilently()
            } else if withInteraction {
                self.acquireTokenInteractively()
            } else {
                self.logout()
            }
        }
    }

    func logout() {
        msAuthProxy.logout { error in
            if let error = error {
                Logger.msAuthentication.error("Couldn't sign out account with error: \(String(describing: error))")
                self.resetState()
                return
            }

            Logger.msAuthentication.debug("Sign out completed successfully")
            self.resetState()
        }
    }

    func openUrl(url: URL) {
        msAuthProxy.openUrl(url: url)
    }
    
    private func setupApplicationContext() {
        guard let authorityURL = URL(string: msAuthority) else {
            Logger.msAuthentication.error("Unable to create authority URL")
            return
        }
        
        do {
            try msAuthProxy.setupApplicationContext(msAuthorityUrl: authorityURL, msRedirectUri: msRedirectUri)
        } catch let error {
            Logger.msAuthentication.error("Unable to create Application Context: \(String(describing: error))")
        }
    }
    
    private func loadAccount(completion: ((Account?) -> Void)? = nil) {
        msAuthProxy.loadAccount { account, error in
            if let error = error {
                Logger.msAuthentication.error("Couldn't query current account with error: \(String(describing: error))")
                return
            }

            if let account = account {
                Logger.msAuthentication.error("Found a signed in account \(account.email ?? ""). Updating data for that account...")
                completion?(account)
                return
            }

            Logger.msAuthentication.debug("Account signed out.")
            self.resetState()
            completion?(nil)
        }
    }
    
    private func resetState() {
        setAccount(nil)
    }
    
    private func setAccount(_ account: Account?) {
        DispatchQueue.main.async {
            self.appState.account = account
        }
    }

    private func acquireTokenInteractively() {
        msAuthProxy.acquireTokenInteractively(msScopes: msScopes) { account, accessToken, error in
            if let error = error {
                Logger.msAuthentication.error("Could not acquire token: \(String(describing: error))")
                return
            }

            guard let account = account, let accessToken = accessToken  else {
                Logger.msAuthentication.error("Could not acquire token: No result returned")
                return
            }

            self.accessToken = accessToken
            Logger.msAuthentication.debug("Aquired access token interactively")
            self.setAccount(account)
            self.loadContentWithToken(accessToken: accessToken)
        }
    }

    private func acquireTokenSilently() {
        msAuthProxy.acquireTokenSilently(msScopes: msScopes) { account, accessToken, error in
            if let error = error {
                if let error = error as? MSAuthError, error == .interactiveLoginRequired {
                    DispatchQueue.main.async {
                        self.acquireTokenInteractively()
                    }
                } else {
                    Logger.msAuthentication.error("Could not acquire token silently: \(String(describing: error))")
                }
                return
            }

            guard let account = account, let accessToken = accessToken else {
                Logger.msAuthentication.error("Could not acquire token: No result returned")
                return
            }

            self.accessToken = accessToken
            self.setAccount(account)
            self.loadContentWithToken(accessToken: accessToken)
            Logger.msAuthentication.debug("Refreshed Access token")
        }
    }
    
    func loadDeviceMode() {
        msAuthProxy.deviceMode { deviceMode, error in
            if let deviceMode = deviceMode {
                Logger.msAuthentication.log("Received device info. Device is in the \(deviceMode) mode.")
            } else {
                Logger.msAuthentication.error("Device info not returned. Error: \(String(describing: error))")
            }
        }
    }

    private func loadContentWithToken(accessToken: String) {
        var request = URLRequest(url: URL(string: msGraphEndpoint + "/v1.0/me/")!)

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                Logger.msAuthentication.error("Couldn't get graph result: \(String(describing: error))")
                return
            }

            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {

                Logger.msAuthentication.error("Couldn't deserialize result JSON")
                return
            }

            Logger.msAuthentication.log("Result from Graph: \(String(describing: result)))")
        }.resume()
    }
}


