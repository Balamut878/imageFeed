//
//  AuthViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 25.12.2024.
//

import UIKit
import ProgressHUD

/// Протокол, чтобы Auth мог сообщить Splash (или другому VC), что мы получили токен
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

final class AuthViewController: UIViewController {
    
    private let oauth2Service = OAuth2Service.shared         // ваш сервис OAuth
    private let oauth2TokenStorage = OAuth2TokenStorage()    // хранилище токена
    weak var delegate: AuthViewControllerDelegate?           // делегат (обычно SplashViewController)

    /// Идентификатор сегвея на WebView (должен быть Show (Push) в сториборде)
    let identifier = "ShowWebView"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    /// Настройка кастомной кнопки «Назад» без текста, если хотите убрать текст "Back"
    private func configureBackButton() {
        if let navigationController = navigationController {
            navigationController.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
            navigationController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        }
        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        backButtonItem.tintColor = UIColor(named: "YP Black") // или ваш цвет
        navigationItem.backBarButtonItem = backButtonItem
    }
    
    /// Подготовка к переходу на WebView (по Show (Push) segue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == identifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        // Если сейчас уже крутится HUD, не запускаем ещё раз
        guard !UIBlockingProgressHUD.isDisplayed() else { return }
        
        // Достаём WebViewViewController
        guard let webViewViewController = segue.destination as? WebViewViewController else {
            assertionFailure("Failed to prepare for \(identifier)")
            return
        }
        // Становимся делегатом WebView
        webViewViewController.delegate = self
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    /// Вызывается, когда Unsplash вернул code
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        // Так как WebView перешли push'ем, убираем WebView через pop
        navigationController?.popViewController(animated: true)
        
        // Показываем индикатор, пока идёт запрос за токеном
        UIBlockingProgressHUD.show()
        
        // Запрашиваем токен
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            // Скрываем индикатор после ответа
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let token):
                // Сохраняем токен (можно и в Splash, но у вас сделано здесь)
                self.oauth2TokenStorage.token = token
                print("Успешно получен токен: \(token)")
                
                // Уведомляем делегата (обычно Splash), что авторизация прошла
                self.delegate?.didAuthenticate(self, didAuthenticateWithCode: token)
            case .failure(let error):
                print("Ошибка авторизации: \(error.localizedDescription)")
                // Показываем Alert
                self.showAuthErrorAlert()
            }
        }
    }
    
    /// Если пользователь закрыл WebView без логина
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        // Раз тоже push, возвращаемся назад
        navigationController?.popViewController(animated: true)
    }
    
    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
