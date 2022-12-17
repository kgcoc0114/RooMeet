//
//  ChatViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/4.
//

import UIKit
import FirebaseFirestore

class ChatViewController: UIViewController {
    enum Section: CaseIterable {
        case message
    }

    typealias DataSource = UITableViewDiffableDataSource<Section, ChatItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ChatItem>
    private var dataSource: DataSource!

    lazy var imagePickerController = UIImagePickerController()

    var chatRoom: ChatRoom?
    var otherData: ChatMember?
    var currentUserData = ChatMember(
        id: UserDefaults.id,
        profilePhoto: UserDefaults.profilePhoto,
        name: UserDefaults.name
    )

    var messages: [Message] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateDataSource()
                self.scrollToButtom(animated: false)
            }
        }
    }

    @IBOutlet weak var otherFunctionButton: UIButton! {
        didSet {
            otherFunctionButton.setTitle("", for: .normal)
        }
    }

    private var listener: ListenerRegistration?

    @IBOutlet weak var contentTextField: UITextField! {
        didSet {
            contentTextField.placeholder = " Aa"
        }
    }

    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var imageButton: UIButton! {
        didSet {
            imageButton.setTitle("", for: .normal)
        }
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.separatorStyle = .none
            tableView.showsVerticalScrollIndicator = false
            tableView.backgroundColor = UIColor.mainBackgroundColor
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let phoneBarButton = UIBarButtonItem(
            image: UIImage.asset(.circle_phone).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(call))

        let infoBarButton = UIBarButtonItem(
            image: UIImage.asset(.comment_info).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(userAction))

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.asset(.back).withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backAction))

        navigationItem.rightBarButtonItems = [infoBarButton, phoneBarButton]

        tableView.delegate = self
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // listen
        guard let chatRoom = chatRoom else {
            print("ERROR: chatRoom is not exist.")
            return
        }

        FIRChatRoomService.shared.listenToMessageUpdate(chatRoomID: chatRoom.id) { [weak self] messages, error in
            guard let self = self else { return }
            if let error = error {
                print("Error getting documents: \(error)")
            }
            self.messages = messages ?? []
        }

        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func setup(chatRoom: ChatRoom) {
        self.chatRoom = chatRoom

        otherData = chatRoom.member ?? ChatMember(id: "test", profilePhoto: "", name: "test")

        navigationItem.title = otherData?.name
    }

    @IBAction func sendMessage(_ sender: Any) {
        if let content = contentTextField.text,
            !content.isEmpty {
            guard let room = chatRoom else {
                print("ERROR: chatRoom is not exist.")
                return
            }

            let messageRef = Firestore.firestore()
                .collection("ChatRoom")
                .document(room.id)
                .collection("Message")
                .document()

            let message = Message(
                id: messageRef.documentID,
                messageType: 0,
                sendBy: UserDefaults.id,
                content: content,
                createdTime: Timestamp()
            )

            do {
                try messageRef.setData(from: message)
            } catch let error {
                print("Error writing Message to Firestore: \(error)")
            }

            guard let chatRoom = chatRoom else {
                return
            }

            let chatRoomRef = FirestoreEndpoint.chatRoom.colRef.document(chatRoom.id)
            let lastMessage = LastMessage(id: messageRef.documentID, content: content, createdTime: message.createdTime)

            chatRoomRef.updateData([
                "lastMessage": lastMessage.toDict,
                "lastUpdated": lastMessage.createdTime
            ])
        }

        contentTextField.text = ""
    }

    private func scrollToButtom(animated: Bool = true) {
        tableView.scrollToButtom(at: .bottom, animated: animated)
    }

    @IBAction func addImageAction(_ sender: Any) {
        imagePickerController.delegate = self

        let imagePickerAlertController = UIAlertController(
            title: "上傳圖片",
            message: "請選擇要上傳的圖片",
            preferredStyle: .actionSheet
        )

        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.imagePickerController.sourceType = .photoLibrary
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }
        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }

        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(cancelAction)

        present(imagePickerAlertController, animated: true, completion: nil)
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: false)
    }

    @objc private func call(_ sender: Any) {
        guard
            let chatRoom = chatRoom,
            let otherData = otherData else {
            return
        }

        // 清空通話資料
        FirestoreEndpoint.call.colRef.document(chatRoom.id).delete { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }

        let callViewController = CallViewController(
            callRoomId: chatRoom.id,
            callType: .offer,
            callerData: currentUserData,
            calleeData: otherData
        )

        callViewController.otherUserData = otherData
        callViewController.currentUserData = currentUserData
        callViewController.modalPresentationStyle = .fullScreen
        present(callViewController, animated: true)
    }

    @objc private func userAction(_ sender: Any) {
        let userActionAlertController = UIAlertController(
            title: "封鎖 \(otherData?.name ?? "") ?",
            message: "他們將無法在 RooMeet 發訊息給你或找到你的貼文。你封鎖用戶時，對方不會收到通知。",
            preferredStyle: .actionSheet
        )

        let blockUserAction = UIAlertAction(title: "封鎖用戶", style: .destructive) { [weak self] _ in
            guard
                let self = self,
                let blockUser = self.otherData
            else { return }

            let blockUserID = blockUser.id

            FirebaseService.shared.insertBlock(blockedUser: blockUserID)

            RMProgressHUD.showSuccess()
            self.navigationController?.popViewController(animated: true)
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            userActionAlertController.dismiss(animated: true)
        }

        userActionAlertController.addAction(blockUserAction)
        userActionAlertController.addAction(cancelAction)

        present(userActionAlertController, animated: true, completion: nil)
    }
}

extension ChatViewController {
    private func configureDataSource() {
        tableView.registerCellWithNib(identifier: OUTextCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: CUTextCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: CUCallCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: OUCallCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: CUReservationCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: OUReservationCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: CUImageCell.identifier, bundle: nil)
        tableView.registerCellWithNib(identifier: OUImageCell.identifier, bundle: nil)

        dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: item.cellIdentifier,
                for: indexPath
            ) as? ChatCell else {
                return UITableViewCell()
            }

            cell.configure(for: item.chatData)
            let messageType = MessageType(rawValue: item.chatData.message.messageType)

            switch messageType {
            case .image:
                if item.chatData.message.sendBy == UserDefaults.id {
                    (cell as? CUImageCell)?.delegate = self
                } else {
                    (cell as? OUImageCell)?.delegate = self
                }
            default:
                print("")
            }
            return cell
        }
    }
}

extension ChatViewController {
    private func updateDataSource() {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(Section.allCases)

        newSnapshot.appendItems(messages.map { ChatItem.message(
            ChatData(message: $0, otherUser: otherData, currentUser: currentUserData)
        ) }, toSection: .message)

        dataSource.apply(newSnapshot, animatingDifferences: false)
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        RMProgressHUD.show()
        // 取得從 UIImagePickerController 選擇的檔案
        if let pickedImage = info[.originalImage] as? UIImage {
            FIRStorageService.shared.uploadImage(image: pickedImage, path: "ChatImages") { [weak self] imageURL, error in
                guard
                    let self = self,
                    let imageURL = imageURL else {
                    return
                }

                if error != nil {
                    RMProgressHUD.showFailure(text: "傳送圖片出現問題")
                } else {
                    self.sendMessage(content: imageURL.absoluteString, messageType: .image)
                }
            }
        }

        picker.dismiss(animated: true)
    }

    private func sendMessage(content: String, messageType: MessageType) {
        guard let room = chatRoom else {
            print("ERROR: chatRoom is not exist.")
            return
        }

        let messageRef = Firestore.firestore()
            .collection("ChatRoom")
            .document(room.id)
            .collection("Message")
            .document()

        let message = Message(
            id: messageRef.documentID,
            messageType: messageType.rawValue,
            sendBy: UserDefaults.id,
            content: content,
            createdTime: Timestamp()
        )

        do {
            try messageRef.setData(from: message)
        } catch let error {
            print("Error writing Message to Firestore: \(error)")
        }

        guard let chatRoom = chatRoom else {
            return
        }

        let chatRoomRef = FirestoreEndpoint.chatRoom.colRef.document(chatRoom.id)

        var lastMessageContent = content

        if messageType == .image {
            lastMessageContent = "已傳送圖片"
        }

        let lastMessage = LastMessage(
            id: messageRef.documentID,
            content: lastMessageContent,
            createdTime: message.createdTime
        )

        chatRoomRef.updateData([
            "lastMessage": lastMessage.toDict,
            "lastUpdated": lastMessage.createdTime
        ])

        RMProgressHUD.showSuccess()
    }
}

extension ChatViewController: OUImageCellDelegate {
    func didClickImageView(_ cell: OUImageCell, imageURL: String) {
        let imageViewVC = ChatImageViewController(imageURL: imageURL)
        imageViewVC.modalPresentationStyle = .fullScreen
        self.present(imageViewVC, animated: false)
    }
}

extension ChatViewController: CUImageCellDelegate {
    func didClickImageView(_ cell: CUImageCell, imageURL: String) {
        let imageViewVC = ChatImageViewController(imageURL: imageURL)
        imageViewVC.modalPresentationStyle = .fullScreen
        self.present(imageViewVC, animated: false)
    }
}
