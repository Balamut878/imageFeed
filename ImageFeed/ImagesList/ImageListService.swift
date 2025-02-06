//
//  ImageListService.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.01.2025.
//

import Foundation
import UIKit

final class ImagesListService {
    static let shared = ImagesListService()
    
    private(set) var photos: [Photo] = []
    
    private var lastLoadedPage: Int?
    private var isLoading = false
    private let tokenStorage = OAuth2TokenStorage()
    
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private lazy var dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    private init() {}
    
    func clean() {
        photos = []
        lastLoadedPage = nil
        isLoading = false
    }
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let method = isLike ? "POST" : "DELETE"
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = tokenStorage.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            DispatchQueue.main.async {
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    self.photos[index].isLiked.toggle()
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: nil,
                        userInfo: ["photoId": photoId]
                    )
                }
                completion(.success(()))
            }
        }.resume()
    }
    
    func fetchPhotosNextPage() {
        guard !isLoading else { return }
        isLoading = true
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        let urlString = "https://api.unsplash.com/photos?page=\(nextPage)&per_page=10"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        if let token = tokenStorage.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                print("Ошибка загрузки: \(error)")
                return
            }
            
            guard let data = data else {
                print("Ошибка: нет данных")
                return
            }
            
            do {
                let photoResults = try self.decoder.decode([PhotoResult].self, from: data)
                
                let newPhotos = photoResults.map { photo in
                    Photo(
                        id: photo.id,
                        size: CGSize(width: photo.width, height: photo.height),
                        createdAt: self.dateFormatter.date(from: photo.createdAt ?? ""),
                        description: photo.description,
                        thumbImageURL: photo.urls.thumb ?? "",
                        largeImageURL: photo.urls.full ?? "",
                        isLiked: photo.likedByUser
                    )
                }
                
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    
                    self.photos.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
            }
        }.resume()
    }
}
