//
//  ImageCell.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 28.01.2025.
//

import Foundation
import UIKit
import Kingfisher

final class ImageCell: UITableViewCell {
    
    @IBOutlet private var photoImageView: UIImageView!
    
    func configure(with photo: Photo) {
        let url = URL(string: photo.thumbImageURL)
        photoImageView.kf.setImage(with: url)
    }
}
