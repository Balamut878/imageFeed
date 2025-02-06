//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 23.11.2024.
//

import UIKit

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    @IBOutlet weak var gradient: UIView!
    @IBOutlet weak var imageCell: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dataLabel: UILabel!
    
    weak var delegate: ImagesListCellDelegate?
    
    private let gradientLayer = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGradient()
    }
    
    private func setupGradient() {
        
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]
        
        gradientLayer.locations = [0.0, 1.0]
        gradient.layer.insertSublayer(gradientLayer, at: 0)
        gradient.layer.cornerRadius = 16
        gradient.layer.masksToBounds = true
        gradient.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradient.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageCell.kf.cancelDownloadTask()
        imageCell.image = nil
    }
    @IBAction private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let likeImageName = isLiked ? "Active" : "No Active"
        let likeImage = UIImage(named: likeImageName)
        likeButton.setImage(likeImage, for: .normal)
    }
    
}
