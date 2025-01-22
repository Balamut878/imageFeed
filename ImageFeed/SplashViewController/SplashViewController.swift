//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.12.2024.
//

import UIKit

// Экран запуска теперь полностью программный
final class SplashViewController: UIViewController {
    // MARK: UI(Верстка кодом)
    private let logoImageView: UIImageView = {
        // Добавляем картинку
        let imageView = UIImageView(image: UIImage(named: "splash_screen_logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    } ()
    
    // MARK: Сервисы
    
    // Сервис для получения OAuth токена
    private let oAuth2Service = OAuth2Service.shared
    // Хранилище токена через SwiftKeychainWrapper
    private let oAuth2TokenStorage = OAuth2TokenStorage()
    // Сервис профиля
    private let profileService = ProfileService.shared
    
    // MARK: Жизненный цикл контроллера
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Настраиваем фон
        view.backgroundColor = .ypBlack
        // Добавляем логотип
        view.addSubview(logoImageView)
        // Констрейнты
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    // Вызываеться когда экран уже показан пользователю
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Проверяем есть ли уже загруженный токен
        if let token = oAuth2TokenStorage.token {
            fetchProfile(token: token)
        } else {
            showAuthViewController()
        }
    }
    
    // MARK: Auth
    
    private func showAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            fatalError("AuthViewController не найден в сториборде")
        }
        authViewController.delegate = self
        // Презентуем на весь экран
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController,animated: true)
    }
    
    // MARK: Логика профиля и таббара
    
    // Запрашиваем данные профиля пользователя
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token: token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case .success(let profile):
                    // При успешной загрузке профиля сразу подгружаем аватар
                    ProfileImageService.shared.fetchProfileImageURL(userName: profile.username) { _ in
                    }
                    // Переходим к TabBar
                    self.switchToTabBarController()
                case .failure(let error):
                    print("Ошибка загрузки профиля: \(error.localizedDescription)")
                }
            }
        }
    }
    // Заменяем rootViewController на TabBarController
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Ошибка: невозможно получить окно приложения")
        }
        guard let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            assertionFailure("Ошибка: невозможно найти TabBarViewController в сториборде")
            return
        }
        // Становимся корневым контроллером
        window.rootViewController = tabBarController
    }
    // После успешной авторизации получаем токен и грузим профиль
    private func fetchOAuthToken(_ code: String) {
        oAuth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                self.fetchProfile(token: token)
            case .failure(let error):
                print("Ошибка авторизации: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        // Закрываем экран авторизации
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            // Запрашиваем токен
            self.fetchOAuthToken(code)
        }
    }
}
