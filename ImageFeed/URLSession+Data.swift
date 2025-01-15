//
//  URLSession+Data.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 29.12.2024.
//

import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int) // Ошибка HTTP-статуса
    case urlRequestError(Error) // Ошибка запроса
    case urlSessionError // Ошибка сессии
    case decodingError(Error, Data) // Ошибка декодирования + сырые данные
}

extension URLSession {
    /// Выполняет HTTP-запрос с асинхронной обработкой результата
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        // Оборачивает результат в главный поток для выполнения завершения
        let fulfillCompletionOnMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        // Создание задачи для выполнения запроса
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                // Если произошла ошибка запроса
                print("data(for:) -> urlRequestError: \(error.localizedDescription)")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                // Если отсутствует корректный HTTP-ответ
                print("data(for:) -> urlSessionError (нет httpResponse)")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
                return
            }
            
            if !(200..<300).contains(httpResponse.statusCode) {
                // Если HTTP-статус-код не находится в диапазоне успешных
                print("data(for:) -> httpStatusCode: \(httpResponse.statusCode)")
                fulfillCompletionOnMainThread(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                // Если данные отсутствуют
                print("data(for:) -> нет data")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
                return
            }
            
            // Успешный результат с данными
            fulfillCompletionOnMainThread(.success(data))
        }
        
        task.resume()
        return task
    }
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void) -> URLSessionTask {
            let task = data(for: request) { (result: Result<Data, Error>) in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let decodedObject = try decoder.decode(T.self, from: data)
                        completion(.success(decodedObject))
                    } catch {
                        print("objectTask(for:) -> ошибка декодирования: \(error.localizedDescription)")
                        print("Данные: \(String(data: data, encoding: .utf8) ?? "")")
                        completion(.failure(NetworkError.decodingError(error, data)))
                    }
                case .failure(let error):
                    print("objectTask(for:) -> ошибка при получение Data: \(error)")
                    completion(.failure(error))
                }
            }
            return task
        }
}
