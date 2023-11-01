//  ProfileEditViewController.swift
//  Poki-iOS
//
//  Created by Insu on 10/20/23.
//

import UIKit
import SnapKit
import Then
import PhotosUI

final class ProfileEditVC: UIViewController {
    
    // MARK: - Properties
    
    let firestoreManager = FirestoreManager.shared
    
    private var userImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.borderWidth = 1.0
        $0.layer.borderColor = UIColor.systemGray5.cgColor
        $0.layer.cornerRadius = 75
        $0.clipsToBounds = true
    }
    
    private var nicknameLabel = UILabel().then {
        $0.text = "닉네임"
        $0.font = UIFont(name: Constants.fontBold, size: 16)
        $0.textColor = .black
        $0.textAlignment = .left
    }
    
    private lazy var nicknameTextField = UITextField().then {
        $0.placeholder = "닉네임을 입력하세요"
        $0.font = UIFont(name: Constants.fontRegular, size: 14)
        $0.borderStyle = .roundedRect
        $0.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
    }
    
    private var hintLabel = UILabel().then {
        $0.text = "닉네임을 입력해주세요!"
        $0.font = UIFont(name: Constants.fontMedium, size: 14)
        $0.textColor = .systemRed
        $0.isHidden = false
    }
    
    private var stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 10
    }
    
    private lazy var selectImageButton = UIButton().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 15
        $0.backgroundColor = .white
        $0.tintColor = .lightGray
        $0.clipsToBounds = true
        $0.setImage(UIImage(systemName: "camera"), for: .normal)
        
        $0.layer.shadowColor = UIColor.lightGray.cgColor
        $0.layer.shadowOpacity = 0.5
        $0.layer.shadowOffset = CGSize(width: 2, height: 4)
        $0.layer.shadowRadius = 2
        $0.layer.masksToBounds = false
        
        $0.addTarget(self, action: #selector(selectImageButtonTapped), for: .touchUpInside)
    }

    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureNav()
        configureUI()
        configureTextField()
    }
    
    
    // MARK: - Helpers
    
    private func configureNav() {
        navigationItem.title = "프로필 수정"
        navigationController?.configureBasicAppearance()
        let doneButton = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    private func configureUI() {
        view.addSubviews(userImageView, selectImageButton, stackView)
        stackView.addArrangedSubviews(nicknameLabel, nicknameTextField, hintLabel)
        
        userImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            $0.centerX.equalTo(view)
            $0.width.height.equalTo(150)
        }
        
        selectImageButton.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.leading).offset(245)
            $0.top.equalTo(view.snp.top).offset(230)
            $0.width.height.equalTo(30)
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.height.equalTo(50)
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(userImageView.snp.bottom).offset(50)
            $0.leading.equalTo(view).offset(20)
            $0.trailing.equalTo(view).offset(-20)
        }
        
    }
    
    private func configureTextField() {
        nicknameTextField.text = firestoreManager.userData[0].userName
        if nicknameTextField.text == "" {
            hintLabel.isHidden = false
        } else {
            hintLabel.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func selectImageButtonTapped() {
        let action = UIAction(title: "갤러리에서 선택하기", image: UIImage(systemName: "photo.on.rectangle")) { _ in
            self.requestPhotoLibraryAccess()
        }
        
        let menu = UIMenu(title: "", children: [action])
        
        selectImageButton.menu = menu
        selectImageButton.showsMenuAsPrimaryAction = true
    }
    
    @objc private func doneButtonTapped() {
        let userData = firestoreManager.userData[0].documentReference
        firestoreManager.userProfileUpdate(documentPath:  userData, name: nicknameTextField.text ?? "", image: "")
    }
    
    @objc private func textFieldEditingChanged() {
        if let text = nicknameTextField.text, text.isEmpty {
            hintLabel.isHidden = false
        } else {
            hintLabel.isHidden = true
        }
    }
}


extension ProfileEditVC {
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // 사용자가 권한을 허용한 경우
                // 여기에서 사진 라이브러리에 접근할 수 있습니다.
                let fetchOptions = PHFetchOptions()
                let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
                DispatchQueue.main.async {
                    self.setupImagePicker()
                    // 사진에 접근하여 무엇인가 작업 수행
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "사진 접근 거부됨", message: "사진에 접근하려면 설정에서 권한을 허용해야 합니다.", preferredStyle: .alert)
                    let settingsAction = UIAlertAction(title: "설정 열기", style: .default) { _ in
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                        }
                    }
                    let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
                    alertController.addAction(settingsAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            case .notDetermined: break
                // 사용자가 아직 결정을 내리지 않은 경우
                // 다음에 권한 요청을 수행할 수 있습니다.

            case .limited:
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 30 // 최신 30장만 가져옴
                @unknown default:
                break
            }
        }
    }
    
    private func setupImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func limitedImageUpload(image: UIImage, picker: PHPickerViewController) {
        let maxSizeInBytes: Int = 4 * 1024 * 1024
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            if imageData.count > maxSizeInBytes {
                let alertController = UIAlertController(title: "경고", message: "이미지 파일이 너무 큽니다.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alertController.addAction(okAction)
                picker.dismiss(animated: true, completion: nil)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
}

extension ProfileEditVC: PHPickerViewControllerDelegate {
    // 사진이 선택이 된 후에 호출되는 메서드
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                DispatchQueue.main.async {
                    let dataImage = image as? UIImage
                    self.limitedImageUpload(image: dataImage!, picker: picker)
                    self.userImageView.image  = dataImage
                }
            }
        } else {
            print("이미지 로드 실패")
        }
    }
}
