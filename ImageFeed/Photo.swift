//
//  Photo.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.01.2025.
//

import Foundation
import CoreGraphics

struct Photo: Decodable {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let description: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case width
        case height
        case createdAt
        case description
        case urls
        case likedByUser = "liked_by_user"
    }
    
    enum URLKeys: String, CodingKey {
        case thumb
        case full
    }
    
    init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        size = CGSize(width: width, height: height)
        createdAt = try? ISO8601DateFormatter() .date(from: container.decode(String.self, forKey: .createdAt))
        description = try? container.decode(String.self, forKey: .description)
        isLiked = try container.decode(Bool.self, forKey: .likedByUser)
        
        let urlContainer = try container.nestedContainer(keyedBy: URLKeys.self, forKey: .urls)
        thumbImageURL = try urlContainer.decode(String.self, forKey: .thumb)
        largeImageURL = try urlContainer.decode(String.self, forKey: .full)
    }
    
    init(
        id: String,
        size: CGSize,
        createdAt: Date?,
        description: String?,
        thumbImageURL: String,
        largeImageURL: String,
        isLiked: Bool
    ) {
        self.id = id
        self.size = size
        self.createdAt = createdAt
        self.description = description
        self.thumbImageURL = thumbImageURL
        self.largeImageURL = largeImageURL
        self.isLiked = isLiked
    }
}
