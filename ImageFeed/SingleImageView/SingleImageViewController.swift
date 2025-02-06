//
//  SingleImageViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 03.12.2024.
//

import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    // MARK: - Public properties
    
    var imageURL: URL?
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        
        imageView.contentMode = .scaleAspectFit
        
        if let image {
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        } else {
            loadFullImage()
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
    // MARK: - Private methods
    
    private func loadFullImage() {
        guard let imageURL else { return }
        
        UIBlockingProgressHUD.show()
        
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            guard let self = self else { return }
            
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let value):
                self.image = value.image
            case .failure:
                self.showErrorAlert { [weak self] in
                    self?.loadFullImage()
                }
            }
        }
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        view.layoutIfNeeded()
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size
        
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let scale = max(widthScale, heightScale)
        
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
        
        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        centerImage()
    }
    
    private func centerImage() {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size
        
        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    private func showErrorAlert(retryHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { _ in
            retryHandler()
        }))
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
