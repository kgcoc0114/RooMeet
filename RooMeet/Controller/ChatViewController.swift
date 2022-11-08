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
//        case call
    }

    enum Item: Hashable {
        case message(Message)
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
        print("===listenCall()")
        listenCall()
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

    @IBAction func call(_ sender: Any) {



        guard let chatRoom = chatRoom else {
            return
        }
        Firestore.firestore().collection("Call").document(chatRoom.id).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        let callViewController = CallViewController(chatRoom: chatRoom, callType: .offer)
        callViewController.otherUserData = otherData
        present(callViewController, animated: true)
    }

    func listenCall() {
        Firestore.firestore().collection("Call").document(chatRoom!.id)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                do {
                    print("====",123)
                    let call = try document.data(as: Call.self)
                    if call.caller != gCurrentUser.id && call.status == "offer" {
                        print("需要接電話")
                        guard let chatRoom = self?.chatRoom else {
                            return
                        }

                        let callViewController = CallViewController(chatRoom: chatRoom, callType: .answer)
                        callViewController.otherUserData = self?.otherData
                        self?.present(callViewController, animated: true)
                    }
                } catch let DecodingError.dataCorrupted(context) {
                    print(context)
                } catch let DecodingError.keyNotFound(key, context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch let DecodingError.valueNotFound(value, context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch let DecodingError.typeMismatch(type, context) {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch {
                    print("error: ", error)
                }
            }
    }
}

extension ChatViewController {
    private func configureDataSource() {
        tableView.register(
            UINib(nibName: OtherUserMsgCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: OtherUserMsgCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: CurrentUserMsgCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: CurrentUserMsgCell.reuseIdentifier
        )

        tableView.register(
            UINib(nibName: CallCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: CallCell.reuseIdentifier
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
                    }
                }
            })
    }

    private func configureCurrentUserCell(tableView: UITableView, indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CurrentUserMsgCell.reuseIdentifier,
            for: indexPath
        ) as? CurrentUserMsgCell else {
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
