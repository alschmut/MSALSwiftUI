//
//  AppResolver.swift
//  ace-life
//
//  Created by Alexander Schmutz on 24.07.21.
//

import Foundation
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { MSAuthState() }.scope(.application)
        register { MSAuthAdapter() }.scope(.application)
    }
}

func resolve<TService>() -> TService {
    return Resolver.resolve()
}
