//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.12.2024.
//

import Foundation
import SwiftKeychainWrapper

enum AuthServiceError: Error {
    case invalidRequest
}

// Структура описывающая тело ответа от сервера при получении токена
struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let createdAt: Int
}

// Хранилище токена. Теперь вместо UserDefaults используеться SwiftKeychainWrapper
final class OAuth2TokenStorage {
    // Ключ под которым будет зраниться токен в Keychain
    private let tokenKey = "Bearer Token"
    
    // Основное свойство чтение, запись токена
    var token: String? {
        get {
            // Считываем строку из Keychain по ключу tokenKey
            KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let newValue = newValue {
                // Сохраняем новый токен в Keychain
                KeychainWrapper.standard.set(newValue, forKey: tokenKey)
            } else {
                // Удаляем запись из Keychain, если присвоили nil
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
}

// Класс отвечающий за получение токена через OAuth2 и хранение его в OAuth2TokenStorage
final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    // URLSession для сетевых запросов
    private let urlSession = URLSession.shared
    
    // Экземпляр класса который хранит токен
    private let tokenStorage = OAuth2TokenStorage()
    
    // Текущая задача что бы избежать повторных запросов
    private var task: URLSessionTask?
    private var lastCode: String?
    
    // Набор completion блоков что бы уведомить всех кто запросил токен
    private var completionHandlers: [(Result<String,Error>) -> Void] = []
    
    // Функция создает запрос на получение OAuth токена с сервера Unsplash
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
    
    // Уведомляет все сохраненные completion блоки об итоговом результате
    private func completeAll(with result: Result<String, Error>) {
        completionHandlers.forEach{ $0(result) }
        completionHandlers = []
    }
    
    // Запрашиваем новый OAuth токен
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Убеждаемся что вызываем из основного потока
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
        
        // Формируем запрос для получения токена
        guard let request = makeOAuthTokenRequest(code: code) else {
            let error = AuthServiceError.invalidRequest
            completeAll(with: .failure(error))
            return
        }
        
        // Делаем сетевой запрос
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.task = nil
                self.lastCode = nil
                
                switch result {
                case .success(let tokenResponse):
                    // Сохраняем accessToken в Keychain через наш tokenStorage
                    self.tokenStorage.token = tokenResponse.accessToken
                    // Уведомляем всех о его результате
                    self .completeAll(with: .success(tokenResponse.accessToken))
                    
                case .failure(let error):
                    print("fetchOAuthToken ошибка: \(error)")
                    self.completeAll(with: .failure(error))
                }
            }
        }
        self.task = task
        task.resume()
    }
}
