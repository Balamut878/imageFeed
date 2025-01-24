//
//  ProfileImageService.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 14.01.2025.
//

import Foundation

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}
    
    private var task: URLSessionTask?
    private var lastUserName: String?
    
    private(set) var avatarURL: String?
    
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChage")
    
    func fetchProfileImageURL(userName: String, completion: @escaping (Result<String, Error>) -> Void) {
        if lastUserName == userName {
            task?.cancel()
        }
        lastUserName = userName
        
        guard let url = URL(string: "https://api.unsplash.com/users/\(userName)") else {
            let error = NSError(domain: "ProfileImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            let error = NSError(domain: "ProfileImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No OAuth token found"])
            completion(.failure(error))
            return
        }
        task?.cancel()
        
        task = URLSession.shared.objectTask(for: request) { [ weak self] (result: Result<UserResult, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success( let userResult):
                let smallImageURL = userResult.profileImage.small
                self.avatarURL = smallImageURL
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": smallImageURL]
                    )
                }
                completion(.success(smallImageURL))
                
            case .failure(let error):
                print("fetchProfileImageURL ошибка: \(error)")
                completion(.failure(error))
            }
        }
        task?.resume()
    }
}
struct UserResult: Codable {
    let profileImage: UserProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}
struct UserProfileImage: Codable {
    let small: String
}

