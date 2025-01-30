//
//  ViewController.swift
//  ImageFeed
//
//  Created by Александр Дудченко on 23.11.2024.
//

import UIKit

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    private let imagesListService = ImagesListService.shared
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        // Начинаем загрузку первой страницы
        imagesListService.fetchPhotosNextPage()
        
        // Подписка на обновление данных
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.updateTableViewAnimated()
        }
    }
    deinit {
        if let observer = imagesListServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    // Переход к полноэкранному фото 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else{
                assertionFailure("Invalid Segue destination")
                return
            }
            let imageUrl = photos[indexPath.row].largeImageURL
            viewController.imageURL = URL(string: imageUrl)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    // Метод который добавляет новые строки в таблицу
    private func updateTableViewAnimated() {
        // Запоминаем сколько было фото до обновления
        let oldCount = photos.count
        // Смотрим сколько стало
        let newCount = imagesListService.photos.count
        // Обновляем массив
        photos = imagesListService.photos
        
        print("Обновление таблицы: старый счетчик = \(oldCount), новый счетчик = \(newCount)") // УДАЛИТЬ!!!
        
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }
}

// MARK: UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    // Сколько строк в таблице
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    // Настройка каждой ячейки
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as! ImagesListCell
        // Настраиваем содержимое
        configCell(for: cell, with: indexPath)
        return cell
    }
}

// MARK: UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
    // Переход к полноразмерному фото
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    // Возвращаем высоту ячейки
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}
// MARK: Cell Configuration
extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        
        print("Настройка ячейки \(indexPath.row) с фото \(photo.id)") // УДАЛИТЬ!!!
        
        // Показываем индикатор загрузки
        cell.imageCell.kf.indicatorType = .activity
        
        // Загрузка изображения с placeholder
        if let url = URL(string: photo.thumbImageURL) {
            cell.imageCell.kf.setImage(with:url, placeholder: UIImage(named: "placeholder"))
        }
        // Форматирование даты
        if let createdAt = photo.createdAt {
            cell.dataLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dataLabel.text = "Неизвестная дата"
        }
        // Обновляем состояние лайка
        cell.setIsLiked(photo.isLiked)
        
        cell.delegate = self
    }
}
extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        
        // Блокируем
        UIBlockingProgressHUD.show()

        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            // Скрываем лоадер
            defer {
                UIBlockingProgressHUD.dismiss()
            }
            
            switch result {
            case .success():
                DispatchQueue.main.async {
                    self.photos = self.imagesListService.photos
                    cell.setIsLiked(self.photos[indexPath.row].isLiked)
                }
            case .failure(let error):
                print("Ошибка лайка: \(error)")
            }
        }
    }
}

