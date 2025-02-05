//
//  ProfileLogoutService.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 03.02.2025.
//

import Foundation
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() {}
    
    func logout() {
        OAuth2TokenStorage().token = nil
        
        ImagesListService.shared.clean()
        ProfileService.shared.clean()
        
        cleanCookies()
    }
    
    private func cleanCookies() {
        
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: record.dataTypes,
                    for: [record],
                    completionHandler: {}
                )
            }
        }
    }
}
