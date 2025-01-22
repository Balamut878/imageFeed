//
//  TabBarController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 22.01.2025.
//

import UIKit

final class TabBarController: UITabBarController {
    override func awakeFromNib() {
        super.awakeFromNib()
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        // Для ImageListViewController
        let imagesListViewController = storyboard.instantiateViewController(withIdentifier: "ImageListViewController")
        // Для ProfileViewController
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil)
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
