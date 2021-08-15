//
//  MSAuthState.swift
//  ace-life
//
//  Created by Alexander Schmutz on 14.08.21.
//

import Foundation
import MSAL

class MSAuthState: ObservableObject {
    @Published var currentAccount: MSALAccount?
    @Published var logMessage = ""
}
