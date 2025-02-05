//
//  AuthViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 25.12.2024.
//

import UIKit
import ProgressHUD

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

final class AuthViewController: UIViewController {
    
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage()
    weak var delegate: AuthViewControllerDelegate?
    
    
    let identifier = "ShowWebView"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    private func configureBackButton() {
        if let navigationController = navigationController {
            navigationController.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
            navigationController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        }
        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        backButtonItem.tintColor = UIColor(named: "YP Black")
        navigationItem.backBarButtonItem = backButtonItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == identifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        
        guard !UIBlockingProgressHUD.isDisplayed() else { return }
        
        
        guard let webViewViewController = segue.destination as? WebViewViewController else {
            assertionFailure("Failed to prepare for \(identifier)")
            return
        }
        
        webViewViewController.delegate = self
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        navigationController?.popViewController(animated: true)
        
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let token):
                self.oauth2TokenStorage.token = token
                print("Успешно получен токен: \(token)")
                
                self.delegate?.didAuthenticate(self, didAuthenticateWithCode: token)
                
                self.restartAppAfterLogin()
                
            case .failure(let error):
                print("Ошибка авторизации: \(error.localizedDescription)")
                // Показываем Alert
                self.showAuthErrorAlert()
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
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
    
    private func restartAppAfterLogin() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
    }
}
