//
//  Logger+Categories.swift
//  MSALSwiftUI
//
//  Created by Alexander Schmutz on 31.01.22.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let msAuthentication = Logger(subsystem: subsystem, category: "MSAL_Authentication")
}
