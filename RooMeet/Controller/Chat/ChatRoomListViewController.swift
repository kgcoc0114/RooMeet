//
//  ChatRoomViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import UIKit
import FirebaseFirestore

class ChatRoomListViewController: UIViewController {
    enum Section: CaseIterable {
        case chatRoom
    }

    enum Item: Hashable {
        case chatRoom(ChatRoom)
    }

    typealias DataSource = UITableViewDiffableDataSource<Section, ChatRoom>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ChatRoom>
    private var dataSource: DataSource!
    private var listener: ListenerRegistration?

    var chatRooms: [ChatRoom] = [] {
        didSet {
            updateDataSource()
        }
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.separatorStyle = .none
            tableView.showsVerticalScrollIndicator = false
            tableView.delegate = self
            tableView.register(
                UINib(nibName: ChatRoomCell.reuseIdentifier, bundle: nil),
                forCellReuseIdentifier: ChatRoomCell.reuseIdentifier
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Chat"
        print("Chat ===", UserDefaults.id)
        configureDataSource()
//        FirebaseService.shared.fetchChatRoomDataWithMemberData(userID: gCurrentUser.id) { [weak self] chatRooms in
//            self?.chatRooms = chatRooms
//        }
//        updateDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        FirebaseService.shared.listenToChatRoomUpdate {[weak self] chatRooms, error in
            if let error = error {
                print(
                    "ERROR: FirebaseService listenToChatRoomUpdate",
                    error.localizedDescription
                )
            }

            if let chatRooms = chatRooms {
                DispatchQueue.main.async {
                    self?.chatRooms = chatRooms
                }
            }
        }
    }
}

extension ChatRoomListViewController {
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView,
                                cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatRoomCell.reuseIdentifier,
                for: indexPath
            ) as? ChatRoomCell else {
                return UITableViewCell()
            }
            let chatRoom = self.chatRooms[indexPath.item]
            cell.layoutCell(UserDefaults.id, chatRoom: chatRoom)
            return cell
        })
    }
}

extension ChatRoomListViewController {
    private func updateDataSource() {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(chatRooms.map({ $0 }), toSection: .chatRoom)
        dataSource.apply(newSnapshot, animatingDifferences: false)
    }
}

extension ChatRoomListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatRoom = chatRooms[indexPath.item]
        let detailVC = ChatViewController()
        detailVC.setup(chatRoom: chatRoom)
        navigationController?.pushViewController(detailVC, animated: false)
    }
}
