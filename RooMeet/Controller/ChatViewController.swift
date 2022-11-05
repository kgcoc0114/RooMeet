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

    typealias DataSource = UITableViewDiffableDataSource<Section, Message>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Message>
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
            tableView.register(
                UINib(nibName: OtherUserMsgCell.reuseIdentifier, bundle: nil),
                forCellReuseIdentifier: OtherUserMsgCell.reuseIdentifier
            )

            tableView.register(
                UINib(nibName: CurrentUserMsgCell.reuseIdentifier, bundle: nil),
                forCellReuseIdentifier: CurrentUserMsgCell.reuseIdentifier
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

        FirebaseService.shared.listenToMessageUpdate(roomID: chatRoom.id) { messages, error in
            if let error = error {
                print("Error getting documents: \(error)")
            }
            self.messages = messages ?? []
        }
    }

    @IBAction func sendMessage(_ sender: Any) {
        if let content = contentTextField.text,
           !content.isEmpty {
            let messageRef = Firestore.firestore()
                .collection("ChatRoom")
                .document(chatRoom!.id)
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
    }

    private func scrollToButtom(animated: Bool = true) {
        tableView.scrollToButtom(at: .bottom, animated: animated)
    }
}

extension ChatViewController {
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, _ in
            let message = self.messages[indexPath.item]
            if message.sendBy == currentUserData.id {
                return configureCurrentUserCell(tableView: tableView, indexPath: indexPath)
            } else {
                return configureOtherUserCell(tableView: tableView, indexPath: indexPath)
            }
        })
    }

    private func configureCurrentUserCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CurrentUserMsgCell.reuseIdentifier,
            for: indexPath
        ) as? CurrentUserMsgCell else {
            return UITableViewCell()
        }
        let message = self.messages[indexPath.item]

        cell.msgType = .currentUser
        cell.sendBy = currentUserData
        cell.message = message
        cell.configureLayout()
        return cell
    }

    private func configureOtherUserCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OtherUserMsgCell.reuseIdentifier,
            for: indexPath
        ) as? OtherUserMsgCell else {
            return UITableViewCell()
        }
        let message = self.messages[indexPath.item]

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
        newSnapshot.appendItems(messages.map({ $0 }), toSection: .message)
        dataSource.apply(newSnapshot, animatingDifferences: true)
    }
}
