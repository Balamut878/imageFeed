//
//  WebViewViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 25.12.2024.
//

import UIKit
import WebKit

private enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

final class WebViewViewController: UIViewController {
    
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!
    
    weak var delegate: WebViewViewControllerDelegate?
    
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        estimatedProgressObservation = webView.observe(\.estimatedProgress,
                                                        options: .new) { [weak self] _, _ in
            self?.updateProgress()
        }
        
        loadAuthView()
    }
    
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = abs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            print("Ошибка: не удалось создать URL для авторизации")
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            print("Ошибка: не удалось сформировать URL")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func code(from navigationAction: WKNavigationAction) -> String? {
        guard
            let url = navigationAction.request.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.path == "/oauth/authorize/native",
            let codeItem = urlComponents.queryItems?.first(where: { $0.name == "code" })
        else {
            print("Код не найден в URL")
            return nil
        }
        return codeItem.value
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        if let code = code(from: navigationAction) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - Protocol
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}
