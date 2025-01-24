//
//  UIBlockingProgressHUD.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 09.01.2025.
//

import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    private static var isVisible: Bool = false
    
    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
    static func isDisplayed() -> Bool {
        return isVisible
    }
}
