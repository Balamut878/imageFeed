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
            // Когда картинку присваивают извне (или после загрузки),
            // и view уже загружена, обновляем UI:
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
        
        // Настройка зума для scrollView
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
        
        // Если image уже есть (например, передали извне) — показываем сразу.
        // Иначе пытаемся загрузить по URL.
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
        // 1) Проверяем, есть ли URL
        guard let imageURL else { return }
        
        // 2) Показываем блокирующий лоадер (используя ваш UIBlockingProgressHUD)
        UIBlockingProgressHUD.show()
        
        // 3) Загружаем картинку через Kingfisher
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            guard let self = self else { return }
            // 4) Скрываем лоадер в любом случае
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let value):
                // value.image — итоговая загруженная картинка
                self.image = value.image
            case .failure:
                // Выводим алерт с кнопкой «Повторить»
                self.showErrorAlert { [weak self] in
                    self?.loadFullImage()
                }
            }
        }
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        
        view.layoutIfNeeded()
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        // Выбираем подходящий масштаб в пределах [minZoomScale, maxZoomScale]
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        // Устанавливаем
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let newContentSize = scrollView.contentSize
        let offsetX = (newContentSize.width - visibleRectSize.width) / 2
        let offsetY = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
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
}
