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
        // 1) Стираем токен из Keychain
        OAuth2TokenStorage().token = nil
        
        // 2) Очищаем локальные данные
        ImagesListService.shared.clean()
        ProfileService.shared.clean()
        // Если у вас есть ProfileImageService — тоже обнулить, например:
        // ProfileImageService.shared.avatarURL = nil
        
        // 3) Удаляем cookies
        cleanCookies()
    }
    
    private func cleanCookies() {
        // Удаляем все cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // Удаляем данные из WKWebView
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
