//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.12.2024.
//

import UIKit

final class SplashViewController: UIViewController {
    // MARK: - UI
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "splash_screen_logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Services
    private let oAuth2Service = OAuth2Service.shared
    private let oAuth2TokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = oAuth2TokenStorage.token {
            fetchProfile(token: token)
        } else {
            showAuthViewController()
        }
    }
    
    // MARK: - Показываем Auth
    private func showAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let navController = storyboard.instantiateViewController(
            withIdentifier: "AuthNavigationController"
        ) as? UINavigationController else {
            fatalError("Не найден NavigationController с ID AuthNavigationController")
        }
        guard let authVC = navController.viewControllers.first as? AuthViewController else {
            fatalError("AuthViewController не найден как root в AuthNavigationController")
        }
        authVC.delegate = self
        
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Получение профиля и переход на TabBar
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token: token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case .success(let profile):
                    ProfileImageService.shared.fetchProfileImageURL(
                        userName: profile.username
                    ) { _ in }
                    self.switchToTabBarController()
                case .failure(let error):
                    print("Ошибка загрузки профиля: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Ошибка: нет окна приложения")
        }
        guard let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            assertionFailure("TabBarViewController не найден в сториборде")
            return
        }
        window.rootViewController = tabBarController
    }
    
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

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.fetchOAuthToken(code)
        }
    }
}
