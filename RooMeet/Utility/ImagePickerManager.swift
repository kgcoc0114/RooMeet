//
//  ImagePickerManager.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/10.
//

import UIKit

protocol ImagePickerManagerDelegate: AnyObject {
    func imagePickerController(didSelect: UIImage?)
}

class ImagePickerManager: NSObject {
    private let imagePickerController = UIImagePickerController()
    private weak var presentationController: UIViewController?
    weak var delegate: ImagePickerManagerDelegate?

    public init (presentationController: UIViewController) {
        super.init()
        self.presentationController = presentationController
        imagePickerController.delegate = self
    }

    public func present(from sourceView: UIView) {
        let imagePickerAlertController = UIAlertController(
            title: "上傳圖片",
            message: "請選擇要上傳的圖片",
            preferredStyle: .actionSheet
        )

        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.imagePickerController.sourceType = .photoLibrary
                self.presentationController?.present(self.imagePickerController, animated: true, completion: nil)
            }
        }

        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                self.presentationController?.present(self.imagePickerController, animated: true, completion: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }

        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(cancelAction)

        self.presentationController?.present(imagePickerAlertController, animated: true, completion: nil)
    }

    private func pickerController (_ controls: UIImagePickerController, didSelect image: UIImage?) {
        self.delegate?.imagePickerController(didSelect: image)
        controls.dismiss(animated: true, completion: nil)
    }
}

extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel (_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let pickedImage = info[.originalImage] as? UIImage {
            self.pickerController(picker, didSelect: pickedImage)
        }
    }
}
