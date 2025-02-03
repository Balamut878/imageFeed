//
//  AuthViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 25.12.2024.
//

import UIKit
import ProgressHUD

final class AuthViewController: UIViewController {
    
    private let oauth2Service = OAuth2Service.shared
    weak var delegate: AuthViewControllerDelegate?
    private let oauth2TokenStorage = OAuth2TokenStorage()
    
    let identifier = "ShowWebView"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    //    configureBackButton()
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
    
   // private func configureBackButton() {
     //   if let navigationController = navigationController {
       //     navigationController.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        //    navigationController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
    //    }
        
      // let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
       // backButtonItem.tintColor = UIColor(named: "YP Black")
       // navigationItem.backBarButtonItem = backButtonItem
   // }
 }

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true)
        
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let token):
                self.oauth2TokenStorage.token = token
                self.delegate?.didAuthenticate(self, didAuthenticateWithCode: token)
                print("Успешно получен токен: \(token)")
            case .failure(let error):
                print("Ошибка авторизации: \(error.localizedDescription)")
                self.showAuthErrorAlert()
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true)
    }
    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "ОК",
            style: .default,
            handler: nil))
        present(alert, animated: true)
    }
}


