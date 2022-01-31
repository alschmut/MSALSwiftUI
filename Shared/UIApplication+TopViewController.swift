//
//  UIApplication+TopViewController.swift
//  MSALSwiftUI
//
//  Created by Alexander Schmutz on 31.01.22.
//

import UIKit

extension UIApplication {
    static var topViewController: UIViewController? {
        let window = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        let rootVC = window?.rootViewController
        return rootVC?.top()
    }
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
