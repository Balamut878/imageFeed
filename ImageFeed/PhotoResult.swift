//
//  PhotoResult.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.01.2025.
//

import Foundation
import UIKit
// JSON ответ от Unsplash
struct PhotoResult: Codable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let description: String?
    let urls: UrlsResult
    let likedByUser: Bool
}
// Вложенный объект с URL изображениями
struct UrlsResult: Codable {
    let thumb: String?
    let regular: String?
    let full: String?
}
