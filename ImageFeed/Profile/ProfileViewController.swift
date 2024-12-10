//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 26.11.2024.
//

import UIKit

final class ProfileViewController: UIViewController {
    
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .photo)
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = UIFont.boldSystemFont(ofSize: 23)
        label.textColor = UIColor(resource: .ypWhite)
        return label
    }()
    private let loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(resource: .ypGrey)
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(resource: .ypWhite)
        return label
    }()
    private let logoutButton: UIButton = {
        let button = UIButton()
        button.setImage(.exit, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupLayouts()
        setupAppearance()
    }
    
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
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        view.backgroundColor = UIColor(resource: .ypBlack)
    }
}
