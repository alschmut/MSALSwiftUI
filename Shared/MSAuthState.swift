//
//  MSAuthState.swift
//  ace-life
//
//  Created by Alexander Schmutz on 14.08.21.
//

import Foundation

class MSAuthState: ObservableObject {
    @Published var account: Account?
}

struct Account: Equatable {
    let email: String?
}
