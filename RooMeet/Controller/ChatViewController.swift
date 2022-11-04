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
    @IBOutlet weak var contentTextField: UITextField!
    var currentUserData = ChatMember(id: User.mockUser.id, profilePhoto: User.mockUser.profilePhoto, name: User.mockUser.name)
    var messages: [Message] = [] {
        didSet {
            print(messages)
            updateDataSource()
        }
    }

    private var listener: ListenerRegistration?

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: MessageCell.reuseIdentifier, bundle: nil),
                forCellReuseIdentifier: MessageCell.reuseIdentifier
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
    }

    func setup(chatRoom: ChatRoom) {
        self.chatRoom = chatRoom

        otherData = chatRoom.member ?? ChatMember(id: "test", profilePhoto: "", name: "test")

        navigationItem.title = otherData?.name

        startListener()

//        FirebaseService.shared.fetchMessagesbyRoomID(roomID: chatRoom.id) { messages, error in
//            if let error = error {
//                print("Error getting documents: \(error)")
//            }
//            self.messages = messages ?? []
//            self.startListener()
//        }
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
                sendBy: User.mockUser.id,
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
}

extension ChatViewController {
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MessageCell.reuseIdentifier,
                for: indexPath
            ) as? MessageCell else {
                return UITableViewCell()
            }

            let message = self.messages[indexPath.item]
            if message.sendBy == currentUserData.id {
                cell.msgType = .currentUser
                cell.sendBy = currentUserData
            } else {
                cell.msgType = .other
                cell.sendBy = otherData
            }
            cell.message = message
            cell.configureLayout()
            return cell
        })
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

extension ChatViewController {
    private func startListener() {
        listener = Firestore.firestore().collection("ChatRoom").document(chatRoom!.id)
            .collection("Message").order(by: "createdTime", descending: false)
            .addSnapshotListener({ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshot results: \(error!)")
                    return
                }

                var messages: [Message] = []

                snapshot.documents.forEach { document in
                    do {
                        let item = try document.data(as: Message.self)
                        messages.append(item)
                    } catch let DecodingError.dataCorrupted(context) {
                        print(context)
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.typeMismatch(type, context)  {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch {
                        print("error: ", error)
                    }
                }
                self.messages = messages
            })
    }
}

