//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 26.11.2024.
//

import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    // MARK: Subviews
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        // Зашлушка
        imageView.image = UIImage(resource: .photo)
        // Обрезка содержимого
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 23)
        label.textColor = UIColor(resource: .ypWhite)
        return label
    }()
    private let loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(resource: .ypGrey)
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(resource: .ypWhite)
        return label
    }()
    private let logoutButton: UIButton = {
        let button = UIButton()
        button.setImage(.exit, for: .normal)
        return button
    }()
    // Наблюдатель для уведомления об обновление аватарки
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupLayouts()
        setupAppearance()
        
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        
        // Если профиль уже есть
        if let profile = ProfileService.shared.profile {
            updateUI(with: profile)
            //Дополнительный запрос на обновление аватарки
            ProfileImageService.shared.fetchProfileImageURL(userName: profile.username) { _ in }
        }
        // Подписываемся на уведомление о новой аватарке
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let urlFromUserInfo = notification.userInfo?["URL"] as? String {
                print("Новая аватарка:", urlFromUserInfo)
                self.setAvatarImageWithUrlString(urlFromUserInfo)
            }
        }
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Делаю аватарку круглой
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
    }
    
    @objc private func didTapLogoutButton() {
        let alertController = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        let yesAction = UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // Выход из аккаунта
            ProfileLogoutService.shared.logout()
            // Переход на экран авторизации
            self.switchToAuthViewController()
        }
        
        let noAction = UIAlertAction(title: "Нет", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true)
    }
    
    private func switchToAuthViewController() {
        // Предположим, что у вас AuthViewController в storyboard с id "AuthViewController"
        guard let window = UIApplication.shared.windows.first else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        // Создаём/находим контроллер авторизации
        guard let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            return
        }
        
        // Ставим AuthViewController корневым
        window.rootViewController = authVC
        window.makeKeyAndVisible()
    }
    
    // MARK: UI Setup
    
    private func setupViews() {[
        avatarImageView,
        nameLabel,
        loginNameLabel,
        descriptionLabel,
        logoutButton
        
    ].forEach {
        $0.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview($0)
    }
    }
    private func setupLayouts() {
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor,constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor,constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor,constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
    private func setupAppearance() {
        // Цвет фона
        view.backgroundColor = UIColor(resource: .ypBlack)
    }
    
    // MARK: Update UI
    
    private func updateUI(with profile: Profile) {
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        descriptionLabel.text = profile.bio ?? "Нет описания"
        if let avatarURLString = profile.avatarURL {
            setAvatarImageWithUrlString(avatarURLString)
        }
    }
    private func setAvatarImageWithUrlString(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        avatarImageView.kf.setImage(
            with: url,
            placeholder: UIImage(resource: .photo),
            options: [.cacheOriginalImage]
        )
    }
    
    
}
