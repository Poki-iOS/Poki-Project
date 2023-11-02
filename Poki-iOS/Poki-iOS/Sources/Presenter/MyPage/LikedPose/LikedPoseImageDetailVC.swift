//
//  LikedPoseImageDetailViewController.swift
//  Poki-iOS
//
//  Created by 요시킴 on 2023/10/26.
//

import UIKit
import Then

final class LikedPoseImageDetailVC: UIViewController {
    
    // MARK: - Properties
    
    lazy var poseImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.frame = self.view.bounds
        view.addSubview($0)
        }
    
    var isSelected = true
    
    var bookmarkButton = UIBarButtonItem(image: UIImage(systemName: "star.fill"), style: .plain, target: self, action: #selector(customBarButtonTapped))
 
    var url: String? {
        didSet {
            imageSetup()
        }
    }
    
    let storageManager = StorageManager.shared
    let firestoreManager = FirestoreManager.shared
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNav()
        bookmarkButton = UIBarButtonItem(image: isSelected ? UIImage(systemName: "star.fill") : UIImage(systemName: "star"), style: .plain, target: self, action: #selector(customBarButtonTapped))
        navigationItem.rightBarButtonItem = bookmarkButton
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Helpers
    
    private func configureNav() {
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(handleCloseButton))
        navigationItem.leftBarButtonItem = closeButton
        navigationController?.configureBlackAppearance()
    }
    
    private func imageSetup() {
        guard let url = url else { return }
        storageManager.downloadImage(urlString: url) { [weak self] image in
            self?.poseImageView.image = image
        }
        
    }
    
    // MARK: - Actions
    
    @objc private func handleCloseButton() {
        firestoreManager.poseRealTimebinding { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func customBarButtonTapped() {
        if isSelected {
            firestoreManager.poseImageUpdate(imageUrl: url!, isSelected: false)
            navigationItem.rightBarButtonItem?.image = UIImage(systemName: "star")
            self.isSelected = false
        } else {
            firestoreManager.poseImageUpdate(imageUrl: url!, isSelected: true)
            navigationItem.rightBarButtonItem?.image = UIImage(systemName: "star.fill")
            self.isSelected = true
        }
    }
    
}
