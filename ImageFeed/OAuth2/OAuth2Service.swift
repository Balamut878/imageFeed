//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.12.2024.
//

import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let createdAt: Int
}


final class OAuth2TokenStorage {
    private let tokenKey = "Bearer Token"
    
    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: tokenKey)
        }
    }
}

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage()
    
    private var task: URLSessionTask?
    private var lastCode: String?
    private var completionHandlers: [(Result<String,Error>) -> Void] = []
    
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let baseURL = URL(string: "https://unsplash.com") else {
            assertionFailure("Ошибка: не удалось создать baseURL")
            return nil
        }
        
        guard let url = URL(string: "/oauth/token"
                            + "?client_id=\(Constants.accessKey)"
                            + "&client_secret=\(Constants.secretKey)"
                            + "&redirect_uri=\(Constants.redirectURI)"
                            + "&code=\(code)"
                            + "&grant_type=authorization_code",
                            relativeTo: baseURL) else {
            assertionFailure("Ошибка: не удалось создать URL для токена")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    private func completeAll(with result: Result<String, Error>) {
        completionHandlers.forEach{ $0(result) }
        completionHandlers = []
    }
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if let currentTask = task, lastCode == code {
            completionHandlers.append(completion)
            return
        }
        if let currentTask = task {
            currentTask.cancel()
        }
        
        lastCode  = code
        completionHandlers = [completion]
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            let error = AuthServiceError.invalidRequest
            completeAll(with: .failure(error))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response , error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.task = nil
                self.lastCode = nil
                
                if let error = error {
                    print("Ошибка сети или запроса: \(error.localizedDescription)")
                    self.completeAll(with: .failure(error))
                    return
                }
                guard
                    let data = data,
                    let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200
                else {
                    let error = AuthServiceError.invalidRequest
                    self.completeAll(with: .failure(error))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let tokenResponse = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    
                    self.tokenStorage.token = tokenResponse.accessToken
                    self.completeAll(with: .success(tokenResponse.accessToken))
                } catch {
                    print("Ошибка декодирования ответа: \(error.localizedDescription)")
                    self.completeAll(with: .failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
}
