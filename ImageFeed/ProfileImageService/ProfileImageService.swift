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
        
        let session = URLSession.shared
        task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let error = NSError(domain: "ProfileImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(error))
                return
            }
            do {
                let userResult = try JSONDecoder().decode(UserResult.self, from: data)
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
            } catch {
                completion(.failure(error))
            }
        }
        task?.resume()
    }
}
struct UserResult: Codable {
    let profileImage: ProfileImage
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}
struct ProfileImage: Codable {
    let small: String
}
