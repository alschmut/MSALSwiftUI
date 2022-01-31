//
//  MSAuthProxy.swift
//  ace-life
//
//  Created by Alexander Schmutz on 03.12.21.
//

import UIKit
import MSAL

extension MSALAccount {
    var mappedAccount: Account {
        Account(email: username)
    }
}

enum MSAuthError: Error {
    case interactiveLoginRequired
}

protocol MSAuthProxyProtocol {
    func setupApplicationContext(msAuthorityUrl: URL, msRedirectUri: String) throws
    func connectWith(viewController: UIViewController)
    func loadAccount(completion: @escaping (Account?, Error?) -> Void)
    func logout(completion: @escaping (Error?) -> Void)
    func openUrl(url: URL)
    func acquireTokenInteractively(msScopes: [String], completion: @escaping (Account?, String?, Error?) -> Void)
    func acquireTokenSilently(msScopes: [String], completion: @escaping (Account?, String?, Error?) -> Void)
    func deviceMode(completion: @escaping (String?, Error?) -> Void)
}

class MSAuthProxy: MSAuthProxyProtocol {
    private var applicationContext: MSALPublicClientApplication?
    private var webViewParamaters: MSALWebviewParameters?
    private var account: MSALAccount?
    
    func setupApplicationContext(msAuthorityUrl: URL, msRedirectUri: String) throws {
        let authority = try MSALAADAuthority(url: msAuthorityUrl)
        let msalConfiguration = MSALPublicClientApplicationConfig(
            clientId: MSAuthCredentials.applicationId,
            redirectUri: msRedirectUri,
            authority: authority
        )
        applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
    }
    
    /// needs to be called after the view was initialised so the topViewController can be found
    func connectWith(viewController: UIViewController) {
        webViewParamaters = MSALWebviewParameters(authPresentationViewController: viewController)
    }
    
    func loadAccount(completion: @escaping (Account?, Error?) -> Void) {
        guard let applicationContext = applicationContext else { return }

        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main

        applicationContext.getCurrentAccount(with: msalParameters) { (account, _, error) in
            self.account = account
            completion(account?.mappedAccount, error)
        }
    }
    
    func logout(completion: @escaping (Error?) -> Void) {
        guard
            let applicationContext = applicationContext,
            let account = account
        else {
            completion(nil)
            return
        }

        self.account = nil
        
        let signoutParameters = MSALSignoutParameters(webviewParameters: webViewParamaters!)
        signoutParameters.signoutFromBrowser = false
        
        applicationContext.signout(with: account, signoutParameters: signoutParameters) { (_, error) in
            completion(error)
        }
    }
    
    func openUrl(url: URL) {
        MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: nil)
    }
    
    func acquireTokenInteractively(msScopes: [String], completion: @escaping (Account?, String?, Error?) -> Void) {
        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParamaters else { return }

        let parameters = MSALInteractiveTokenParameters(scopes: msScopes, webviewParameters: webViewParameters)

        applicationContext.acquireToken(with: parameters) { (result, error) in
            self.account = result?.account
            completion(result?.account.mappedAccount, result?.accessToken, error)
        }
    }
    
    func acquireTokenSilently(msScopes: [String], completion: @escaping (Account?, String?, Error?) -> Void) {
        guard let applicationContext = applicationContext else { return }
        guard let account = account else { return }

        let parameters = MSALSilentTokenParameters(scopes: msScopes, account: account)

        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            self.account = result?.account
            var newError: Error? = error
            
            if
                let nsError = error as NSError?,
                nsError.domain == MSALErrorDomain,
                nsError.code == MSALError.interactionRequired.rawValue
            {
                newError = MSAuthError.interactiveLoginRequired
            }
            
            completion(result?.account.mappedAccount, result?.accessToken, newError)

        }
    }
    
    func deviceMode(completion: @escaping (String?, Error?) -> Void) {
        applicationContext?.getDeviceInformation(with: nil) { (deviceInformation, error) in
            
            guard let deviceInfo = deviceInformation else {
                completion(nil, error)
                return
            }
            
            let deviceMode = deviceInfo.deviceMode == .shared ? "shared" : "private"
            completion(deviceMode, error)
        }
    }
}
