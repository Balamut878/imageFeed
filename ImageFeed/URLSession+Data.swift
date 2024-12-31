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
                fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                // Если отсутствует корректный HTTP-ответ
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
                return
            }
            
            if !(200..<300).contains(httpResponse.statusCode) {
                // Если HTTP-статус-код не находится в диапазоне успешных
                fulfillCompletionOnMainThread(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                // Если данные отсутствуют
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
                return
            }
            
            // Успешный результат с данными
            fulfillCompletionOnMainThread(.success(data))
        }
        
        return task
    }
}
