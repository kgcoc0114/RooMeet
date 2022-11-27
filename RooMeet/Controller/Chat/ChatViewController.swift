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

    enum Item: Hashable {
        case message(Message)
    }

    typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!

    var chatRoom: ChatRoom?
    var otherData: ChatMember?
    var currentUserData = ChatMember(
        id: UserDefaults.id,
        profilePhoto: UserDefaults.profilePhoto,
        name: UserDefaults.name
    )

    var messages: [Message] = [] {
        didSet {
            updateDataSource()
            scrollToButtom(animated: false)
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
            contentTextField.placeholder = "Aa"
        }
    }
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.setTitle("", for: .normal)
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

        FirebaseService.shared.listenToMessageUpdate(roomID: chatRoom.id) { [weak self] messages, error in
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

    @IBAction func showRuler(_ sender: Any) {
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
        FirestoreEndpoint.call.colRef.document(chatRoom.id).delete() { err in
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
        let userActionAlertController = UIAlertController(title: "封鎖 \(otherData?.name ?? "") ?", message: "他們將無法在 RooMeet 發訊息給你或找到你的貼文。你封鎖用戶時，對方不會收到通知。", preferredStyle: .actionSheet)

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
        tableView.register(
            UINib(nibName: OUTextCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: OUTextCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: CUTextCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: CUTextCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: CallCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: CallCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: CUReservationCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: CUReservationCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: OUReservationCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: OUReservationCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: OUCallCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: OUCallCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: CUCallCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: CUCallCell.reuseIdentifier
        )

        dataSource = DataSource(
            tableView: tableView,
            cellProvider: {[unowned self] tableView, indexPath, item in
                switch item {
                case .message(let data):
                    let message = data
                    let messageType = MessageType.allCases[message.messageType]
                    let sendByMe = message.sendBy == currentUserData.id

                    switch messageType {
                    case .text:
                        if sendByMe {
                            return configureCurrentUserCell(tableView: tableView, indexPath: indexPath, message: data)
                        } else {
                            return configureOtherUserCell(tableView: tableView, indexPath: indexPath, message: data)
                        }
                    case .image:
                        return UITableViewCell()
                    case .call:
                        if sendByMe {
                            return configureCUCallCell(tableView: tableView, indexPath: indexPath, message: data)
                        } else {
                            return configureOUCallCell(tableView: tableView, indexPath: indexPath, message: data)
                        }
                    case .reservation:
                        if sendByMe {
                            return configureCUReservationCell(tableView: tableView, indexPath: indexPath, message: data)
                        } else {
                            return configureOUReservationCell(tableView: tableView, indexPath: indexPath, message: data)
                        }
                    }
                }
            })
    }

    private func configureCUCallCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CUCallCell.reuseIdentifier,
            for: indexPath
        ) as? CUCallCell else {
            return UITableViewCell()
        }

        cell.sendByMe = true
        cell.sendBy = currentUserData
        cell.message = message
        cell.configureLayout()
        return cell
    }

    private func configureOUCallCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OUCallCell.reuseIdentifier,
            for: indexPath
        ) as? OUCallCell else {
            return UITableViewCell()
        }

        cell.sendByMe = false
        cell.sendBy = otherData
        cell.message = message
        cell.configureLayout()
        return cell
    }

    private func configureCUReservationCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CUReservationCell.reuseIdentifier,
            for: indexPath
        ) as? CUReservationCell else {
            return UITableViewCell()
        }
        cell.otherUser = otherData
        cell.currentUser = currentUserData
        cell.message = message
        cell.configureLayout()
        return cell
    }

    private func configureOUReservationCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OUReservationCell.reuseIdentifier,
            for: indexPath
        ) as? OUReservationCell else {
            return UITableViewCell()
        }
        cell.otherUser = otherData
        cell.currentUser = currentUserData
        cell.message = message
        cell.configureLayout()
        return cell
    }

    private func configureCurrentUserCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CUTextCell.reuseIdentifier,
            for: indexPath
        ) as? CUTextCell else {
            return UITableViewCell()
        }

        cell.msgType = .currentUser
        cell.sendBy = currentUserData
        cell.message = message
        cell.configureLayout()
        return cell
    }

    private func configureOtherUserCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OUTextCell.reuseIdentifier,
            for: indexPath
        ) as? OUTextCell else {
            return UITableViewCell()
        }

        cell.msgType = .other
        cell.sendBy = otherData
        cell.message = message
        cell.configureLayout()
        return cell
    }
}

extension ChatViewController {
    private func updateDataSource() {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(messages.map { Item.message($0) }, toSection: .message)
        dataSource.apply(newSnapshot, animatingDifferences: false)
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
}
