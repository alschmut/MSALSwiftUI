//
//  MSAuthAdapter.swift
//  ace-life
//
//  Created by Alexander Schmutz on 07.08.21.
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//


import Foundation
import MSAL
import os.log

class MSAuthAdapter {
    
    private let msGraphEndpoint = "https://graph.microsoft.com/v1.0/me/"
    private let msAuthority: String = "https://login.microsoftonline.com/\(MSAuthCredentials.directoryId)"
    private let msRedirectUri = "msauth.\(Bundle.main.bundleIdentifier!)://auth"
    private let msScopes: [String] = ["User.Read"]

    private let msAuthState: MSAuthState = resolve()

    private var accessToken = ""
    private var applicationContext: MSALPublicClientApplication?
    private var webViewParamaters: MSALWebviewParameters?

    init() {
        guard let authorityURL = URL(string: msAuthority) else {
            msAuthState.logMessage = "Unable to create authority URL"
            return
        }

        do {
            let authority = try MSALAADAuthority(url: authorityURL)
            let msalConfiguration = MSALPublicClientApplicationConfig(
                clientId: MSAuthCredentials.applicationId,
                redirectUri: msRedirectUri,
                authority: authority
            )

            applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
        } catch let error {
            msAuthState.logMessage = "Unable to create Application Context \(error)"
        }
    }

    /// needs to be called after the view was initialised so the topViewController can be found
    func setupMSAuthentication() {
        if let topViewController = topViewController() {
            self.webViewParamaters = MSALWebviewParameters(authPresentationViewController: topViewController)
        }
    }

    func callGraphAPI() {
        loadCurrentAccount { (account) in
            guard let currentAccount = account else {
                self.acquireTokenInteractively()
                return
            }

            self.acquireTokenSilently(currentAccount)
        }
    }

    func loadCurrentAccount(completion: ((MSALAccount?) -> Void)? = nil) {
        guard let applicationContext = applicationContext else { return }

        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main

        applicationContext.getCurrentAccount(with: msalParameters) { (currentAccount, _, error) in

            if let error = error {
                self.msAuthState.logMessage = "Couldn't query current account with error: \(error)"
                return
            }

            if let currentAccount = currentAccount {
                self.msAuthState.logMessage = "Found a signed in account \(String(describing: currentAccount.username)). Updating data for that account..."

                self.msAuthState.currentAccount = currentAccount
                completion?(currentAccount)
                return
            }

            self.msAuthState.logMessage = "Account signed out. Updating UX"
            self.accessToken = ""
            self.msAuthState.currentAccount = nil

            if let completion = completion {
                completion(nil)
            }
        }
    }

    func signOut() {
        guard let applicationContext = applicationContext else { return }
        guard let account = msAuthState.currentAccount else { return }

        let signoutParameters = MSALSignoutParameters(webviewParameters: webViewParamaters!)
        signoutParameters.signoutFromBrowser = false

        applicationContext.signout(with: account, signoutParameters: signoutParameters) { (_, error) in
            if let error = error {
                self.msAuthState.logMessage = "Couldn't sign out account with error: \(error)"
                return
            }

            self.msAuthState.logMessage = "Sign out completed successfully"
            self.accessToken = ""
            self.msAuthState.currentAccount = nil
        }
    }
    
    func getDeviceMode() {
        self.applicationContext?.getDeviceInformation(with: nil) { (deviceInformation, error) in
            
            guard let deviceInfo = deviceInformation else {
                self.msAuthState.logMessage = "Device info not returned. Error: \(String(describing: error))"
                return
            }
            
            let deviceMode = deviceInfo.deviceMode == .shared ? "shared" : "private"
            self.msAuthState.logMessage = "Received device info. Device is in the \(deviceMode) mode."
        }
    }

    func openUrl(url: URL) {
        // as the onOpenURL modifier does not provide a sourceApplication, i set it to nil.
        // Though I think opening the app with a link is not necessary for this example
        MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: nil)
    }

    private func acquireTokenInteractively() {
        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParamaters else { return }

        let parameters = MSALInteractiveTokenParameters(scopes: msScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount

        applicationContext.acquireToken(with: parameters) { (result, error) in
            if let error = error {
                self.msAuthState.logMessage = "Could not acquire token: \(error)"
                return
            }

            guard let result = result else {
                self.msAuthState.logMessage = "Could not acquire token: No result returned"
                return
            }

            self.accessToken = result.accessToken
            self.msAuthState.logMessage = "Access token is \(self.accessToken)"
            self.msAuthState.currentAccount = result.account
            self.getContentWithToken()
        }
    }

    private func acquireTokenSilently(_ account: MSALAccount!) {
        guard let applicationContext = applicationContext else { return }

        let parameters = MSALSilentTokenParameters(scopes: msScopes, account: account)

        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in

            if let error = error {
                let nsError = error as NSError
                if nsError.domain == MSALErrorDomain && nsError.code == MSALError.interactionRequired.rawValue {
                    DispatchQueue.main.async {
                        self.acquireTokenInteractively()
                    }
                    return
                }

                self.msAuthState.logMessage = "Could not acquire token silently: \(error)"
                return
            }

            guard let result = result else {
                self.msAuthState.logMessage = "Could not acquire token: No result returned"
                return
            }

            self.accessToken = result.accessToken
            self.msAuthState.logMessage = "Refreshed Access token is \(self.accessToken)"
            self.getContentWithToken()
        }
    }

    private func getContentWithToken() {
        var request = URLRequest(url: URL(string: msGraphEndpoint)!)

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                self.msAuthState.logMessage = "Couldn't get graph result: \(error)"
                return
            }

            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {

                self.msAuthState.logMessage = "Couldn't deserialize result JSON"
                return
            }

            self.msAuthState.logMessage = "Result from Graph: \(result))"
        }.resume()
    }
}

private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    let rootVC = window?.rootViewController
    return rootVC?.top()
}

private extension UIViewController {
    func top() -> UIViewController {
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.top() ?? nav
        } else if let tab = self as? UITabBarController {
            return tab.selectedViewController ?? tab
        } else {
            return presentedViewController?.top() ?? self
        }
    }
}
