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
//        case reservation
    }

    enum Item: Hashable {
        case message(Message)
//        case reservation(Message)
//        case call(Message)
    }

    typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!

    var chatRoom: ChatRoom?
    var otherData: ChatMember?
    var currentUserData = ChatMember(id: gCurrentUser.id, profilePhoto: gCurrentUser.profilePhoto, name: gCurrentUser.name)
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

    @IBOutlet weak var contentTextField: UITextField!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.separatorStyle = .none
            tableView.showsVerticalScrollIndicator = false

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "phone"),
            style: .plain,
            target: self,
            action: #selector(call))


        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true

        // listen
        guard let chatRoom = chatRoom else {
            print("ERROR: chatRoom is not exist.")
            return
        }
        FirebaseService.shared.listenToMessageUpdate(roomID: chatRoom.id) { messages, error in
            if let error = error {
                print("Error getting documents: \(error)")
            }
            self.messages = messages ?? []
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
                sendBy: gCurrentUser.id,
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

            let chatRoomRef = Firestore.firestore().collection("ChatRoom").document(chatRoom.id)
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

    @IBAction func addReservation(_ sender: Any) {

    }

    @objc private func call(_ sender: Any) {
        guard let chatRoom = chatRoom else {
            return
        }

        // 清空通話資料
        Firestore.firestore().collection("Call").document(chatRoom.id).delete() { err in
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
            calleeData: otherData!
        )
        callViewController.otherUserData = otherData
        callViewController.currentUserData = currentUserData
        present(callViewController, animated: true)
    }
}

extension ChatViewController {
    private func configureDataSource() {
        tableView.register(
            UINib(nibName: OtherUserMsgCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: OtherUserMsgCell.reuseIdentifier
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
                        guard let cell = tableView.dequeueReusableCell(
                            withIdentifier: CallCell.reuseIdentifier,
                            for: indexPath
                        ) as? CallCell else {
                            return UITableViewCell()
                        }
                        if sendByMe {
                            cell.otherUserView.isHidden = true
                        }

                        cell.sendByMe = sendByMe
                        cell.sendBy = sendByMe ? currentUserData : otherData
                        cell.message = message
                        cell.configureLayout()
                        return cell
                    case .reservation:
                        if sendByMe {
                            return configureCUReservationCell(tableView: tableView, indexPath: indexPath, message: message)
                        } else {
                            return configureOUReservationCell(tableView: tableView, indexPath: indexPath, message: message)
                        }
                    }
                }
            })
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
            withIdentifier: OtherUserMsgCell.reuseIdentifier,
            for: indexPath
        ) as? OtherUserMsgCell else {
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
        newSnapshot.appendItems(messages.map({ Item.message($0) }), toSection: .message)
        dataSource.apply(newSnapshot, animatingDifferences: true)
    }
}